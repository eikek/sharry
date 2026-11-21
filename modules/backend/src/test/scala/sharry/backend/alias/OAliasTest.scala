package sharry.backend.alias

import cats.effect.*
import cats.implicits.*

import sharry.backend.alias.OAlias.AliasInput
import sharry.common.*
import sharry.store.*
import sharry.store.records.{RAccount, RAlias, RAliasMember}

import munit.FunSuite

/** Regression tests for the alias modify endpoint: only the owner of an alias may change
  * it or its members.
  */
class OAliasTest extends FunSuite with StoreFixture {

  private def newAccount(login: String): IO[RAccount] =
    for {
      id <- Ident.randomId[IO]
      now <- Timestamp.current[IO]
    } yield RAccount(
      id,
      CIIdent.unsafe(login),
      AccountSource.intern,
      AccountState.Active,
      Password("test"),
      None,
      admin = false,
      0,
      None,
      now
    )

  private def memberIds(store: Store[IO], aliasId: Ident): IO[Set[Ident]] =
    store.transact(RAliasMember.findForAlias(aliasId)).map(_.map(_._1.accountId).toSet)

  test("a non-owner cannot change the members of another account's alias") {
    withStore { store =>
      OAlias[IO](store).use { oalias =>
        for {
          owner <- newAccount("owner")
          member <- newAccount("member")
          attacker <- newAccount("attacker")
          _ <- List(owner, member, attacker).traverse_(a =>
            store.transact(RAccount.insert(a, "warn"))
          )

          alias <- RAlias.createNew[IO](owner.id, "test", Duration.days(1), true)
          created <- oalias.create(AliasInput(alias, List(member.id)))
          _ = assertEquals(created, AddResult.Success)

          // the alias id is known to the attacker, who tries to add itself
          res <- oalias.modify(
            alias.id,
            attacker.id,
            AliasInput(alias.copy(account = attacker.id), List(attacker.id))
          )
          _ = assert(res.isInstanceOf[AddResult.Failure], s"unexpected: $res")

          members <- memberIds(store, alias.id)
          _ = assertEquals(members, Set(member.id))

          // an alias member is no owner, either
          res2 <- oalias.modify(alias.id, member.id, AliasInput(alias, Nil))
          _ = assert(res2.isInstanceOf[AddResult.Failure], s"unexpected: $res2")
          members2 <- memberIds(store, alias.id)
          _ = assertEquals(members2, Set(member.id))
        } yield ()
      }
    }
  }

  test("the owner can rename an alias id and replace its members") {
    withStore { store =>
      OAlias[IO](store).use { oalias =>
        for {
          owner <- newAccount("owner")
          member <- newAccount("member")
          other <- newAccount("other")
          _ <- List(owner, member, other).traverse_(a =>
            store.transact(RAccount.insert(a, "warn"))
          )

          alias <- RAlias.createNew[IO](owner.id, "test", Duration.days(1), true)
          _ <- oalias.create(AliasInput(alias, List(member.id)))

          newId <- Ident.randomId[IO]
          res <- oalias.modify(
            alias.id,
            owner.id,
            AliasInput(alias.copy(id = newId, name = "renamed"), List(other.id))
          )
          _ = assertEquals(res, AddResult.Success)

          found <- oalias.findById(newId, owner.id)
          _ = assertEquals(found.map(_.alias.name), Some("renamed"))
          oldMembers <- memberIds(store, alias.id)
          _ = assertEquals(oldMembers, Set.empty[Ident])
          newMembers <- memberIds(store, newId)
          _ = assertEquals(newMembers, Set(other.id))
        } yield ()
      }
    }
  }
}
