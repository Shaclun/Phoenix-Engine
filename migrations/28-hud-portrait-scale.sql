USE `phoenix`;

-- Keep the active character model and update only the product-default render pose.
INSERT INTO `phoenix_admin_config` (`configKey`, `payload`)
VALUES ('hudPortrait', '{"rotX":-0.022,"rotY":0.58,"rotZ":1.584,"scale":1.60,"light":1.75}')
ON DUPLICATE KEY UPDATE `payload` = VALUES(`payload`);
