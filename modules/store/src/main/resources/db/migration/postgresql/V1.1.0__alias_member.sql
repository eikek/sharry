CREATE TABLE "alias_member" (
  id VARCHAR(254) NOT NULL PRIMARY KEY,
  alias_id VARCHAR(254) NOT NULL,
  account_id VARCHAR(254) NOT NULL,
  FOREIGN KEY ("alias_id") REFERENCES "alias_"("id") ON DELETE CASCADE,
  FOREIGN KEY ("account_id") REFERENCES "account_"("id") ON DELETE CASCADE,
  UNIQUE ("alias_id", "account_id")
);
