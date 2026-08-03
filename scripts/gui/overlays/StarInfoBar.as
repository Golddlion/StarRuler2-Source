import overlays.InfoBar;
import elements.BaseGuiElement;
import elements.GuiResources;
import elements.Gui3DObject;
import elements.GuiText;
import elements.GuiMarkupText;
import elements.GuiButton;
import elements.GuiSkinElement;
import icons;
from obj_selection import isSelected, selectObject, clearSelection, addToSelection;
import void openOverlay(Object@ obj) from "tabs.GalaxyTab";
from overlays.Construction import ConstructionOverlay;

class StarInfoBar : InfoBar {
	Star@ obj;
	Gui3DObject@ objView;
	ConstructionOverlay@ overlay;

	GuiSkinElement@ nameBox;
	GuiText@ name;

	GuiSkinElement@ stateBox;
	GuiMarkupText@ state;

	ActionBar@ actions;

	StarInfoBar(IGuiElement@ parent) {
		super(parent);
		@alignment = Alignment(Left, Bottom-228, Left+395, Bottom);

		@objView = Gui3DObject(this, Alignment(
			Left-1.f, Top, Right, Bottom+3.f));
		objView.objectRotation = false;
		objView.internalRotation = quaterniond_fromAxisAngle(vec3d(0.0, 0.0, 1.0), -0.15*pi);

		@actions = ActionBar(this, vec2i(305, 172));
		actions.noClip = true;

		int y = 56;
		@nameBox = GuiSkinElement(this, Alignment(Left+12, Top+y, Left+156, Top+y+34), SS_PlainOverlay);
		@name = GuiText(nameBox, Alignment().padded(8, 0));
		name.font = FT_Medium;

		y += 40;
		@stateBox = GuiSkinElement(this, Alignment(Left+12, Top+y, Left+236, Bottom-4), SS_PlainOverlay);
		@state = GuiMarkupText(stateBox, Alignment(Left+8, Top+4, Right-4, Bottom));
		state.memo = true;

		updateAbsolutePosition();
	}

	void updateActions() {
		actions.clear();

		if(obj.owner is playerEmpire) {
			actions.add(ManageStarAction());
			actions.addBasic(obj);
			actions.addEmpireAbilities(playerEmpire, obj);
		}

		actions.init(obj);
	}

	bool compatible(Object@ obj) override {
		return obj.isStar;
	}

	Object@ get() override {
		return obj;
	}

	void set(Object@ obj) override {
		@this.obj = cast<Star>(obj);
		@objView.object = obj;
		updateTimer = 0.0;
		updateActions();
	}

	bool displays(Object@ obj) override {
		if(obj is this.obj)
			return true;
		return false;
	}

	bool showManage(Object@ obj) override {
		if(overlay !is null)
			overlay.remove();
		@overlay = ConstructionOverlay(findTab(), obj);
		visible = false;
		return false;
	}

	void remove() override {
		if(overlay !is null)
			overlay.remove();
		InfoBar::remove();
	}

	double updateTimer = 1.0;
	void update(double time) override {
		updateTimer -= time;
		if(updateTimer <= 0) {
			updateTimer = randomd(0.1,0.9);
			Empire@ owner = obj.owner;

			//Update name
			name.text = obj.name;
			if(owner !is null)
				name.color = owner.color;

			if(owner !is null && owner.valid)
				state.text = locale::ASTEROID_OWNED;
			else
				state.text = locale::ASTEROID_UNOWNED;

			//Update action bar
			updateActions();
		}
	}

	IGuiElement@ elementFromPosition(const vec2i& pos) override {
		IGuiElement@ elem = BaseGuiElement::elementFromPosition(pos);
		if(elem is this)
			return null;
		if(elem is objView) {
			int height = AbsolutePosition.size.height;
			vec2i origin(AbsolutePosition.topLeft.x, AbsolutePosition.botRight.y);
			origin.y += height;
			if(pos.distanceTo(origin) > height * 1.6)
				return null;
		}
		return elem;
	}

	void draw() override {
		if(actions.visible) {
			recti pos = actions.absolutePosition;
			skin.draw(SS_Panel, SF_Normal, recti(pos.topLeft - vec2i(70, 0), pos.botRight + vec2i(0, 20)));
		}
		InfoBar::draw();
	}
};

InfoBar@ makeStarInfoBar(IGuiElement@ parent, Object@ obj) {
	StarInfoBar bar(parent);
	bar.set(obj);
	return bar;
}

class ManageStarAction : BarAction {
	void init() override {
		icon = icons::Manage;
		tooltip = locale::TT_MANAGE_PLANET;
	}

	void call() override {
		selectObject(obj);
		openOverlay(obj);
	}
};
