package
{
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;
	import com.as3nui.nativeExtensions.air.kinect.examples.away3D.JointCubesDemo;
	import com.as3nui.nativeExtensions.air.kinect.examples.away3D.riggedModel.RiggedModelDemo;
	import com.as3nui.nativeExtensions.air.kinect.examples.basic.BasicDemo;
	import com.as3nui.nativeExtensions.air.kinect.examples.cameras.DepthCameraDemo;
	import com.as3nui.nativeExtensions.air.kinect.examples.cameras.InfraredCameraDemo;
	import com.as3nui.nativeExtensions.air.kinect.examples.cameras.RGBCameraDemo;
	import com.as3nui.nativeExtensions.air.kinect.examples.multiple.MultipleDemo;
	import com.as3nui.nativeExtensions.air.kinect.examples.pointCloud.PointCloudDemo;
	import com.as3nui.nativeExtensions.air.kinect.examples.pointCloud.PointCloudRegionsDemo;
	import com.as3nui.nativeExtensions.air.kinect.examples.skeleton.JointRotationsDemo;
	import com.as3nui.nativeExtensions.air.kinect.examples.skeleton.SkeletonDemo;
	import com.as3nui.nativeExtensions.air.kinect.examples.userMask.UserMaskDemo;
	import com.as3nui.nativeExtensions.air.kinect.examples.userMask.UserMaskEnterFrameDemo;
	import com.bit101.components.ComboBox;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;

	[SWF(frameRate="60", width="1024", height="768", backgroundColor="#FFFFFF")]
	public class AIRKinectExamples extends Sprite
	{
		
		public static const DEMO_CLASSES:Vector.<Object> = Vector.<Object>([
			{label: "Basic Demo", data: BasicDemo},
			{label: "RGB Camera Demo", data: RGBCameraDemo},
			{label: "Depth Camera Demo", data: DepthCameraDemo},
			{label: "Infrared Camera Demo", data: InfraredCameraDemo},
			{label: "Point Cloud Demo", data: PointCloudDemo},
			{label: "Point Cloud Regions Demo", data: PointCloudRegionsDemo},
			{label: "Skeleton Demo", data: SkeletonDemo},
			{label: "User Mask Demo", data: UserMaskDemo},
			{label: "User Mask Demo Enter Frame", data: UserMaskEnterFrameDemo},
			{label: "Joint Rotations Demo", data: JointRotationsDemo},
			{label: "Joint Cubes Demo", data: JointCubesDemo},
			{label: "Dual Kinect Demo", data: MultipleDemo},
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
		
		public function set currentDemoClass(value:Class):void
		{
			for(var i:uint = 0; i < DEMO_CLASSES.length; i++)
			{
				if(DEMO_CLASSES[i].data == value)
				{
					this.currentDemoIndex = i;
					return;
				}
			}
		}
		
		private var currentDemo:DemoBase;
		
		private var demoBox:ComboBox;
		
		public function AIRKinectExamples()
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
			currentDemoClass = SkeletonDemo;

			stage.addEventListener(Event.RESIZE, resizeHandler, false, 0, true);
		}
		
		protected function demoSelectHandler(event:Event):void
		{
			currentDemoIndex = demoBox.selectedIndex;
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