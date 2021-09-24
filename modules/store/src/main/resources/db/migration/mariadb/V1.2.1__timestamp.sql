-- change all columns that carry a timestamp from varchar to timestamp

-- account_  (lastlogin, created)
ALTER TABLE `account_` RENAME COLUMN `created` TO `created_old`;
ALTER TABLE `account_` ADD COLUMN `created` timestamp;
UPDATE `account_` SET `created` = STR_TO_DATE(`created_old`, '%Y-%m-%dT%H:%i:%s.%fZ');
ALTER TABLE `account_` MODIFY `created` timestamp NOT NULL;
ALTER TABLE `account_` DROP COLUMN `created_old`;

ALTER TABLE `account_` RENAME COLUMN `lastlogin` TO `lastlogin_old`;
ALTER TABLE `account_` ADD COLUMN `lastlogin` timestamp;
UPDATE `account_` SET `lastlogin` = STR_TO_DATE(`lastlogin_old`, '%Y-%m-%dT%H:%i:%s.%fZ');
ALTER TABLE `account_` DROP COLUMN `lastlogin_old`;

-- alias_ (created)
ALTER TABLE `alias_` RENAME COLUMN `created` TO `created_old`;
ALTER TABLE `alias_` ADD COLUMN `created` timestamp;
UPDATE `alias_` SET `created` = STR_TO_DATE(`created_old`, '%Y-%m-%dT%H:%i:%s.%fZ');
ALTER TABLE `alias_` MODIFY `created` timestamp NOT NULL;
ALTER TABLE `alias_` DROP COLUMN `created_old`;

-- invitation (created)
ALTER TABLE `invitation` RENAME COLUMN `created` TO `created_old`;
ALTER TABLE `invitation` ADD COLUMN `created` timestamp;
UPDATE `invitation` SET `created` = STR_TO_DATE(`created_old`, '%Y-%m-%dT%H:%i:%s.%fZ');
ALTER TABLE `invitation` MODIFY `created` timestamp NOT NULL;
ALTER TABLE `invitation` DROP COLUMN `created_old`;

-- publish_share (created, publish_date, publish_until, last_access)
ALTER TABLE `publish_share` RENAME COLUMN `created` TO `created_old`;
ALTER TABLE `publish_share` ADD COLUMN `created` timestamp;
UPDATE `publish_share` SET `created` = STR_TO_DATE(`created_old`, '%Y-%m-%dT%H:%i:%s.%fZ');
ALTER TABLE `publish_share` MODIFY `created` timestamp NOT NULL;
ALTER TABLE `publish_share` DROP COLUMN `created_old`;

ALTER TABLE `publish_share` RENAME COLUMN `publish_date` TO `publish_date_old`;
ALTER TABLE `publish_share` ADD COLUMN `publish_date` timestamp;
UPDATE `publish_share` SET `publish_date` = STR_TO_DATE(`publish_date_old`, '%Y-%m-%dT%H:%i:%s.%fZ');
ALTER TABLE `publish_share` MODIFY `publish_date` timestamp NOT NULL;
ALTER TABLE `publish_share` DROP COLUMN `publish_date_old`;

ALTER TABLE `publish_share` RENAME COLUMN `publish_until` TO `publish_until_old`;
ALTER TABLE `publish_share` ADD COLUMN `publish_until` timestamp;
UPDATE `publish_share` SET `publish_until` = STR_TO_DATE(`publish_until_old`, '%Y-%m-%dT%H:%i:%s.%fZ');
ALTER TABLE `publish_share` MODIFY `publish_until` timestamp NOT NULL;
ALTER TABLE `publish_share` DROP COLUMN `publish_until_old`;

ALTER TABLE `publish_share` RENAME COLUMN `last_access` TO `last_access_old`;
ALTER TABLE `publish_share` ADD COLUMN `last_access` timestamp;
UPDATE `publish_share` SET `last_access` = STR_TO_DATE(`last_access_old`, '%Y-%m-%dT%H:%i:%s.%fZ');
ALTER TABLE `publish_share` DROP COLUMN `last_access_old`;

-- share (created)
ALTER TABLE `share` RENAME COLUMN `created` TO `created_old`;
ALTER TABLE `share` ADD COLUMN `created` timestamp;
UPDATE `share` SET `created` = STR_TO_DATE(`created_old`, '%Y-%m-%dT%H:%i:%s.%fZ');
ALTER TABLE `share` MODIFY `created` timestamp NOT NULL;
ALTER TABLE `share` DROP COLUMN `created_old`;

-- share_file (created)
ALTER TABLE `share_file` RENAME COLUMN `created` TO `created_old`;
ALTER TABLE `share_file` ADD COLUMN `created` timestamp;
UPDATE `share_file` SET `created` = STR_TO_DATE(`created_old`, '%Y-%m-%dT%H:%i:%s.%fZ');
ALTER TABLE `share_file` MODIFY `created` timestamp NOT NULL;
ALTER TABLE `share_file` DROP COLUMN `created_old`;
