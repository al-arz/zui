package zui;

using kha.graphics2.GraphicsExtension;

@:access(zui.Zui)
class Canvas {

	public static var assetMap = new Map<Int, Dynamic>(); // kha.Image | kha.Font
	static var events:Array<String> = [];

	public static var screenW = -1;
	public static var screenH = -1;
	public static var locale = "en";
	static var _ui: Zui;
	static var h = new zui.Zui.Handle(); // TODO: needs one handle per canvas

	public static function draw(ui: Zui, canvas: TCanvas, g: kha.graphics2.Graphics): Array<String> {

		if (screenW == -1) {
			screenW = kha.System.windowWidth();
			screenH = kha.System.windowHeight();
		}

		events = [];

		_ui = ui;

		g.end();
		ui.begin(g); // Bake elements
		g.begin(false);

		ui.g = g;

		for (elem in canvas.elements) {
			if (elem.parent == null) drawElement(ui, canvas, elem);
		}

		g.end();
		ui.end(); // Finish drawing
		g.begin(false);

		return events;
	}

	static function drawElement(ui: Zui, canvas: TCanvas, element: TElement, px = 0.0, py = 0.0) {

		if (element == null || element.visible == false) return;

		var cw = scaled(canvas.width);
		var ch = scaled(canvas.height);

		switch (element.anchor) {
		case Top:
			px -= (cw - screenW) / 2;
		case TopRight:
			px -= cw - screenW;
		case CenterLeft:
			py -= (ch - screenH) / 2;
		case Center:
			px -= (cw - screenW) / 2;
			py -= (ch - screenH) / 2;
		case CenterRight:
			px -= cw - screenW;
			py -= (ch - screenH) / 2;
		case BottomLeft:
			py -= ch - screenH;
		case Bottom:
			px -= (cw - screenW) / 2;
			py -= ch - screenH;
		case BottomRight:
			px -= cw - screenW;
			py -= ch - screenH;
		}

		ui._x = canvas.x + scaled(element.x) + scaled(px);
		ui._y = canvas.y + scaled(element.y) + scaled(py);
		ui._w = scaled(element.width);

		var rotated = element.rotation != null && element.rotation != 0;
		if (rotated) ui.g.pushRotation(element.rotation, ui._x + scaled(element.width) / 2, ui._y + scaled(element.height) / 2);

		switch (element.type) {
		case Text:
			var font = ui.ops.font;
			var size = ui.fontSize;
			var tcol = ui.t.TEXT_COL;

			var fontAsset = element.asset != null && StringTools.endsWith(element.asset, '.ttf');
			if (fontAsset) ui.ops.font = getAsset(canvas, element.asset);
			ui.fontSize = scaled(element.height);
			ui.t.TEXT_COL = element.color_text;
			ui.text(getText(canvas, element));

			ui.ops.font = font;
			ui.fontSize = size;
			ui.t.TEXT_COL = tcol;

		case Button:
			var bh = ui.t.BUTTON_H;
			ui.t.BUTTON_H = scaled(element.height);
			ui.t.BUTTON_COL = element.color;
			ui.t.BUTTON_TEXT_COL = element.color_text;
			ui.t.BUTTON_HOVER_COL = element.color_hover;
			ui.t.BUTTON_PRESSED_COL = element.color_press;
			if (ui.button(getText(canvas, element))) {
				var e = element.event;
				if (e != null && e != "") events.push(e);
			}
			ui.t.BUTTON_H = bh;

		case Image:
			var image = getAsset(canvas, element.asset);
			var fontAsset = element.asset != null && StringTools.endsWith(element.asset, '.ttf');
			if (image != null && !fontAsset) {
				ui.imageScrollAlign = false;
				var tint = element.color != null ? element.color : 0xffffffff;
				if (ui.image(image, tint, scaled(element.height)) == zui.Zui.State.Released) {
					var e = element.event;
					if (e != null && e != "") events.push(e);
				}
				ui.imageScrollAlign = true;
			}

		case FRectangle:
			var col = ui.g.color;
			ui.g.color = element.color;
			ui.g.fillRect(ui._x, ui._y, ui._w, scaled(element.height));
			ui.g.color = col;

		case FCircle:
			var col = ui.g.color;
			ui.g.color = element.color;
			ui.g.fillCircle(ui._x + (scaled(element.width) / 2), ui._y + (scaled(element.height) / 2), ui._w / 2);
			ui.g.color = col;

		case Rectangle:
			var col = ui.g.color;
			ui.g.color = element.color;
			ui.g.drawRect(ui._x, ui._y, ui._w, scaled(element.height), element.strength);
			ui.g.color = col;

		case Circle:
			var col = ui.g.color;
			ui.g.color = element.color;
			ui.g.drawCircle(ui._x+(scaled(element.width) / 2), ui._y + (scaled(element.height) / 2), ui._w / 2, element.strength);
			ui.g.color = col;

		case FTriangle:
			var col = ui.g.color;
			ui.g.color = element.color;
			ui.g.fillTriangle(ui._x + (ui._w / 2), ui._y, ui._x, ui._y + scaled(element.height), ui._x + ui._w, ui._y + scaled(element.height));
			ui.g.color = col;

		case Triangle:
			var col = ui.g.color;
			ui.g.color = element.color;
			ui.g.drawLine(ui._x + (ui._w / 2), ui._y, ui._x, ui._y + scaled(element.height), element.strength);
			ui.g.drawLine(ui._x, ui._y + scaled(element.height), ui._x + ui._w, ui._y + scaled(element.height), element.strength);
			ui.g.drawLine(ui._x + ui._w, ui._y + scaled(element.height), ui._x + (ui._w / 2), ui._y, element.strength);
			ui.g.color = col;

		case Check:
			ui.t.TEXT_COL = element.color_text;
			ui.t.ACCENT_COL = element.color;
			ui.t.ACCENT_HOVER_COL = element.color_hover;
			ui.check(h.nest(element.id), getText(canvas, element));

		case Radio:
			ui.t.TEXT_COL = element.color_text;
			ui.t.ACCENT_COL = element.color;
			ui.t.ACCENT_HOVER_COL = element.color_hover;
			ui.inlineRadio(h.nest(element.id), getText(canvas, element).split(";"));

		case Combo:
			ui.t.TEXT_COL = element.color_text;
			ui.t.LABEL_COL = element.color_text;
			ui.t.ACCENT_COL = element.color;
			ui.t.SEPARATOR_COL = element.color;
			ui.t.ACCENT_HOVER_COL = element.color_hover;
			ui.combo(h.nest(element.id), getText(canvas, element).split(";"));

		case Slider:
			ui.t.TEXT_COL = element.color_text;
			ui.t.LABEL_COL = element.color_text;
			ui.t.ACCENT_COL = element.color;
			ui.t.ACCENT_HOVER_COL = element.color_hover;
			ui.slider(h.nest(element.id), getText(canvas, element), 0.0, 1.0, true);

		case TextInput:
			ui.t.TEXT_COL = element.color_text;
			ui.t.LABEL_COL = element.color_text;
			ui.t.ACCENT_COL = element.color;
			ui.t.ACCENT_HOVER_COL = element.color_hover;
			ui.textInput(h.nest(element.id), getText(canvas, element));

		case KeyInput:
			ui.t.TEXT_COL = element.color_text;
			ui.t.LABEL_COL = element.color_text;
			ui.t.ACCENT_COL = element.color;
			ui.t.ACCENT_HOVER_COL = element.color_hover;
			Ext.keyInput(ui, h.nest(element.id), getText(canvas, element));

		case ProgressBar:
			var col = ui.g.color;
			var progress = element.progress_at;
			var totalprogress = element.progress_total;
			ui.g.color = element.color_progress;
			ui.g.fillRect(ui._x, ui._y, ui._w / totalprogress * Math.min(progress, totalprogress), scaled(element.height));
			ui.g.color = element.color;
			ui.g.drawRect(ui._x, ui._y, ui._w, scaled(element.height), element.strength);
			ui.g.color = col;

		case CProgressBar:
			var col = ui.g.color;
			var progress = element.progress_at;
			var totalprogress = element.progress_total;
			ui.g.color = element.color_progress;
			ui.g.drawArc(ui._x + (scaled(element.width) / 2), ui._y + (scaled(element.height) / 2), ui._w / 2, -Math.PI / 2, ((Math.PI * 2) / totalprogress * progress) - Math.PI / 2, element.strength);
			ui.g.color = element.color;
			ui.g.fillCircle(ui._x + (scaled(element.width) / 2), ui._y + (scaled(element.height) / 2), (ui._w / 2) - 10);
			ui.g.color = col;
		case Empty:
		}

		if (element.children != null) {
			for (id in element.children) {
				drawElement(ui, canvas, elemById(canvas, id), element.x + px, element.y + py);
			}
		}

		if (rotated) ui.g.popTransformation();
	}

	static inline function getText(canvas: TCanvas, e: TElement): String {
		return e.text;
	}

	public static function getAsset(canvas: TCanvas, asset: String): Dynamic { // kha.Image | kha.Font {
		for (a in canvas.assets) if (a.name == asset) return assetMap.get(a.id);
		return null;
	}

	static var elemId = -1;
	public static function getElementId(canvas: TCanvas): Int {
		if (elemId == -1) for (e in canvas.elements) if (elemId < e.id) elemId = e.id;
		return ++elemId;
	}

	static var assetId = -1;
	public static function getAssetId(canvas: TCanvas): Int {
		if (assetId == -1) for (a in canvas.assets) if (assetId < a.id) assetId = a.id;
		return ++assetId;
	}

	static function elemById(canvas: TCanvas, id: Int): TElement {
		for (e in canvas.elements) if (e.id == id) return e;
		return null;
	}

	static inline function scaled(f: Float): Int { return Std.int(f * _ui.SCALE); }
}

typedef TCanvas = {
	var name: String;
	var x: Float;
	var y: Float;
	var width: Int;
	var height: Int;
	var elements: Array<TElement>;
	@:optional var assets: Array<TAsset>;
	@:optional var locales: Array<TLocale>;
}

typedef TElement = {
	var id: Int;
	var type: ElementType;
	var name: String;
	var x: Float;
	var y: Float;
	var width: Int;
	var height: Int;
	@:optional var rotation: Null<kha.FastFloat>;
	@:optional var text: String;
	@:optional var event: String;
	@:optional var color: Null<Int>;
	@:optional var color_text: Null<Int>;
	@:optional var color_hover: Null<Int>;
	@:optional var color_press: Null<Int>;
	@:optional var color_progress: Null<Int>;
	@:optional var progress_at: Null<Int>;
	@:optional var progress_total: Null<Int>;
	@:optional var strength: Null<Int>;
	@:optional var anchor: Null<Int>;
	@:optional var parent: Null<Int>; // id
	@:optional var children: Array<Int>; // ids
	@:optional var asset: String;
	@:optional var visible: Null<Bool>;
}

typedef TAsset = {
	var id: Int;
	var name:String;
	var file:String;
}

typedef TLocale = {
	var name: String; // "en"
	var texts: Array<TTranslatedText>;
}

typedef TTranslatedText = {
	var id: Int; // element id
	var text: String;
}

@:enum abstract ElementType(Int) from Int to Int {
	var Text = 0;
	var Image = 1;
	var Button = 2;
	var Empty = 3;
	// var HLayout = 4;
	// var VLayout = 5;
	var Check = 6;
	var Radio = 7;
	var Combo = 8;
	var Slider = 9;
	var TextInput = 10;
	var KeyInput = 11;
	var FRectangle = 12;
	var Rectangle = 13;
	var FCircle = 14;
	var Circle = 15;
	var FTriangle = 16;
	var Triangle = 17;
	var ProgressBar = 18;
	var CProgressBar = 19;
}

@:enum abstract Anchor(Int) from Int to Int {
	var TopLeft = 0;
	var Top = 1;
	var TopRight = 2;
	var CenterLeft = 3;
	var Center = 4;
	var CenterRight = 5;
	var BottomLeft = 6;
	var Bottom = 7;
	var BottomRight = 8;
}
