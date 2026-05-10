

class Draw3d
{
	labels = null
	projector = null

	_visible = false
	_positionPx = null
	_worldPosition = null
	_distance = 1000
	_sizePx = null
	_scale = null
	_color = null
	_font = "FONT_OLD_10_WHITE_HI.TGA"

	constructor(x, y, z)
	{
		_positionPx = Vec2i(0, 0)
		_sizePx = Vec2i(0, 0)
		_scale = Vec2i(1.0, 1.0)
		_color = Color(255, 255, 255, 255)

		labels = []

		_worldPosition = Vec3(x, y, z)
	}

	function _get(idx)
	{
		switch (idx)
		{
			case "width": return getWidth()
			case "height": return getHeight()
			case "widthPx": return getWidthPx()
			case "heightPx": return getHeightPx()
			case "linesCount": return labels.len()
			case "distance": return _distance
			case "font": return _font
			case "color": return _color
			case "visible": return _visible
		}
		throw null
	}

	function _set(idx, val)
	{
		switch (idx)
		{
			case "distance": return setDistance(val)
			case "font": return setFont(val)
			case "color": return setColor(val)
			case "visible": return setVisible(val)
		}
		throw null
	}

	function onVisibilityChange(visible)
	{
		foreach (label in labels)
			label.visible = visible
	}

	function onUpdate(positionPx, deltaDistance)
	{
		_positionPx.set(positionPx.x - _sizePx.width / 2, positionPx.y - _sizePx.height / 2)

		local lineY = _positionPx.y
		foreach (label in labels)
		{
			local lineX = _positionPx.x - label.widthPx / 2
			lineX += _sizePx.width / 2
			label.setPositionPx(lineX, lineY)
			lineY += label.heightPx
		}
	}

	function createProjector()
	{
		projector = Projector3d(_worldPosition.x, _worldPosition.y, _worldPosition.z, _distance)
		projector.onVisibilityChange = this.onVisibilityChange.bindenv(this)
		projector.onUpdate = this.onUpdate.bindenv(this)
	}

	function getWorldPosition() { return _worldPosition }
	function setWorldPosition(x, y, z) {
		_worldPosition.set(x, y, z)
		if (projector) projector.position.set(x, y, z)
	}

	function getPosition() { return Vec2i(anx(_positionPx.x), any(_positionPx.y)) }
	function getPositionPx() { return _positionPx }
	function getWidth() { return anx(_sizePx.width) }
	function getWidthPx() { return _sizePx.width }
	function getHeight() { return any(_sizePx.height) }
	function getHeightPx() { return _sizePx.height }

	function updateSize()
	{
		local oldFont = textGetFont()
		textSetFont(_font)
		_sizePx.width = 0
		_sizePx.height = 0
		foreach (label in labels)
		{
			if (label.widthPx > _sizePx.width) _sizePx.width = label.widthPx
			_sizePx.height += letterHeightPx()
		}
		textSetFont(oldFont)
	}

	function setVisible(visible)
	{
		if (visible == _visible) return
		_visible = visible
		if (!visible) {
			foreach (label in labels) label.visible = visible
			projector = null
		} else {
			createProjector()
		}
	}

	function setFont(font)
	{
		_font = font
		foreach (label in labels) label.font = font
	}

	function setColor(color)
	{
		_color.set(color.r, color.g, color.b, color.a)
		foreach (label in labels) label.color.set(color.r, color.g, color.b, color.a)
	}

	function setDistance(distance)
	{
		_distance = distance
		if (projector) projector.distance = distance
	}

	function top() { foreach (label in labels) label.top() }

	function getScale() { return _scale }
	function setScale(width, height)
	{
		_scale.set(width, height)
		foreach (label in labels) label.setScale(width, height)
	}

	function insertText(text)
	{
		local label = Label(0, 0, text)
		label.visible = _visible
		label.font = _font
		label.color.set(_color.r, _color.g, _color.b, _color.a)
		labels.push(label)
		updateSize()
	}

	function removeText(idx) { labels.remove(idx); updateSize() }

	function getText()
	{
		local result = []
		foreach (label in labels) result.push(label.text)
		return result
	}

	function getLineText(idx) { return labels[idx].text }
	function setLineText(idx, text) { labels[idx].text = text; updateSize() }
	function getLineFont(idx) { return labels[idx].font }
	function setLineFont(idx, font) { labels[idx].font = font; updateSize() }
	function getLineColor(idx) { return labels[idx].color }
	function setLineColor(idx, r, g, b) { labels[idx].color.set(r, g, b) }
	function getLineAlpha(idx) { return labels[idx].color.a }
	function setLineAlpha(idx, alpha) { labels[idx].color.a = alpha }

	function setText(text)
	{
		if (labels.len() == 0) { insertText(text); return }
		setLineText(0, text)
	}

	function remove()
	{
		setVisible(false)
		labels.clear()
	}
}
