USE `phoenix`;

-- Product default from the HUD portrait preview. The model/texture still
-- comes from the active character; this stores only render positioning.
INSERT INTO `phoenix_admin_config` (`configKey`, `payload`)
VALUES ('hudPortrait', '{"rotX":-0.022,"rotY":0.58,"rotZ":1.584,"scale":1.68,"light":1.75}')
ON DUPLICATE KEY UPDATE `payload` = VALUES(`payload`);