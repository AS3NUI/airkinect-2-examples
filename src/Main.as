package
{
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;
	import com.as3nui.nativeExtensions.air.kinect.examples.away3D.JointCubesDemo;
	import com.as3nui.nativeExtensions.air.kinect.examples.away3D.riggedModel.RiggedModelDemo;
	import com.as3nui.nativeExtensions.air.kinect.examples.basic.BasicDemo;
	import com.as3nui.nativeExtensions.air.kinect.examples.cameras.DepthCameraDemo;
	import com.as3nui.nativeExtensions.air.kinect.examples.cameras.InfraredCameraDemo;
	import com.as3nui.nativeExtensions.air.kinect.examples.cameras.RGBCameraDemo;
	import com.bit101.components.ComboBox;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	
	[SWF(frameRate="60", width="1024", height="768", backgroundColor="#FFFFFF")]
	public class Main extends Sprite
	{
		
		public static const DEMO_CLASSES:Vector.<Object> = Vector.<Object>([
			{label: "Basic Demo", data: BasicDemo},
			{label: "RGB Camera Demo", data: RGBCameraDemo},
			{label: "Depth Camera Demo", data: DepthCameraDemo},
			{label: "Infrared Camera Demo", data: InfraredCameraDemo},
			{label: "Joint Cubes Demo", data: JointCubesDemo},
			{label: "3D Character Demo", data: RiggedModelDemo}
		]);
		
		private var _currentDemoIndex:int = -1;
		public function get currentDemoIndex():int { return _currentDemoIndex; }
		
		public function set currentDemoIndex(value:int):void
		{
			if(value == -1) value = DEMO_CLASSES.length - 1;
			if(value >= DEMO_CLASSES.length) value = 0;
			if (_currentDemoIndex == value)
				return;
			_currentDemoIndex = value;
			currentDemoChanged();
		}
		
		private var currentDemo:DemoBase;
		
		private var demoBox:ComboBox;
		
		public function Main()
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.nativeWindow.visible = true;
			
			demoBox = new ComboBox(this, 10, 10);
			demoBox.setSize(200, demoBox.height);
			demoBox.addEventListener(Event.SELECT, demoSelectHandler, false, 0, true);
			
			for each(var demoItem:Object in DEMO_CLASSES)
			{
				demoBox.addItem(demoItem);
			}
			
			//start default demo
			currentDemoIndex = 5;
			
			stage.addEventListener(Event.RESIZE, resizeHandler, false, 0, true);
			//stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler, false, 0, true);
		}
		
		protected function demoSelectHandler(event:Event):void
		{
			currentDemoIndex = demoBox.selectedIndex;
		}
		
		protected function keyUpHandler(event:KeyboardEvent):void
		{
			switch(event.keyCode)
			{
				case Keyboard.RIGHT:
					currentDemoIndex++;
					break;
				case Keyboard.LEFT:
					currentDemoIndex--;
					break;
			}
		}
		
		private function currentDemoChanged():void
		{
			if(currentDemo != null)
			{
				removeChild(currentDemo);
			}
			demoBox.selectedIndex = _currentDemoIndex;
			currentDemo = new DEMO_CLASSES[_currentDemoIndex].data();
			addChildAt(currentDemo, 0);
			resizeHandler();
		}
		
		protected function resizeHandler(event:Event = null):void
		{
			if(currentDemo != null)
			{
				currentDemo.setSize(stage.stageWidth, stage.stageHeight);
			}
		}
	}
}