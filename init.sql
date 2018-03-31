CREATE TABLE IF NOT EXISTS `t_shorturl`(
	`id`	int(11) unsigned NOT NULL AUTO_INCREMENT,
	`key`	varchar(10) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
	`value`	varchar(1000) NOT NULL,
	`time`	int(10) unsigned NOT NULL,
	PRIMARY KEY (`id`),
	KEY `i_key` (`key`)
)ENGINE = InnoDB DEFAULT CHARSET = utf8;
