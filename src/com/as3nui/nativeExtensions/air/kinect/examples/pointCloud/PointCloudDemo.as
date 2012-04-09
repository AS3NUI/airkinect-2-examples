package com.as3nui.nativeExtensions.air.kinect.examples.pointCloud
{
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.KinectSettings;
	import com.as3nui.nativeExtensions.air.kinect.constants.CameraResolution;
	import com.as3nui.nativeExtensions.air.kinect.events.PointCloudEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;
	import com.bit101.components.CheckBox;
	import com.bit101.components.NumericStepper;
	import com.bit101.utils.MinimalConfigurator;
	
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;

	public class PointCloudDemo extends DemoBase
	{
		
		private var device:Kinect;
		private var renderer:PointCloudRenderer;

		public var chk_pcMirror:CheckBox;
		public var chk_rgbIncluded:CheckBox;
		public var ns_pcDensity:NumericStepper;
		
		override protected function startDemoImplementation():void
		{
			if(Kinect.isSupported())
			{
				device = Kinect.getDevice();

				stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownHandler);
				device.addEventListener(PointCloudEvent.POINT_CLOUD_UPDATE, pointCloudUpdateHandler, false, 0, true);

				var settings:KinectSettings = new KinectSettings();
				if(device.capabilities.hasRGBCameraSupport)
				{
					settings.pointCloudIncludeRGB = true;
				}
				settings.pointCloudEnabled = true;
				settings.pointCloudResolution = CameraResolution.RESOLUTION_320_240;
				settings.pointCloudDensity = 4;

				renderer = new PointCloudRenderer(settings);
				addChild(renderer);

				initUI(settings);

				device.start(settings);
			}
		}

		private function onKeyDownHandler(event:KeyboardEvent):void {
			switch(event.keyCode){
				case Keyboard.C:
					chk_rgbIncluded.selected = !chk_rgbIncluded.selected;
					updatePointCloudSettings();
					break;
				case Keyboard.M:
					chk_pcMirror.selected = !chk_pcMirror.selected;
					updatePointCloudSettings();
					break;
				case Keyboard.UP:
					ns_pcDensity.value++;
					updatePointCloudSettings();
					break;
				case Keyboard.DOWN:
					ns_pcDensity.value--;
					updatePointCloudSettings();
					break;
			}
		}

		private function initUI(settings:KinectSettings):void {
			var config:MinimalConfigurator = new MinimalConfigurator(this);

			var mainLayout:XML = <comps>
				<Window title="Point Cloud Settings" id="wnd_settings" x="10" y="30" width="200" height="150">
					<VBox x="10" y="10" spacing="10">
						<CheckBox label="Point Cloud Mirror" id="chk_pcMirror" event="click:onClick"/>
						<CheckBox label="Point Cloud RGB" id="chk_rgbIncluded" event="click:onClick"/>
						<NumericStepper label="Density" id="ns_pcDensity" minimum="1" maximum="10" event="click:onClick"/>
						<Component height="10"/>
						<Label text="shortcuts are 'C', 'M', 'UP' & 'DOWN' Keys"/>
					</VBox>
				</Window>
			</comps>;

			config.parseXML(mainLayout);

			chk_pcMirror.selected = settings.pointCloudMirrored;
			chk_rgbIncluded.selected = settings.pointCloudIncludeRGB;
			ns_pcDensity.value = settings.pointCloudDensity;
		}

		public function onClick(event:MouseEvent):void {
			updatePointCloudSettings();
		}

		public function updatePointCloudSettings():void {
			if(device.capabilities.hasRGBCameraSupport)
			{
				device.setPointCloudIncludeRGB(chk_rgbIncluded.selected);
				renderer.includeRGB = chk_rgbIncluded.selected;
			}
			device.setPointCloudMirror(chk_pcMirror.selected);
			device.setPointCloudDensity(ns_pcDensity.value);
		}
		
		protected function pointCloudUpdateHandler(event:PointCloudEvent):void
		{
			renderer.updatePoints(event.pointCloudData);
		}
		
		override protected function stopDemoImplementation():void
		{
			if(device != null)
			{
				device.removeEventListener(PointCloudEvent.POINT_CLOUD_UPDATE, pointCloudUpdateHandler);
				device.stop();
			}
		}
		
		override protected function layout():void
		{
			if(renderer != null)
			{
				renderer.x = (explicitWidth - renderer.width) * .5;
				renderer.y = (explicitHeight - renderer.height) * .5;
			}
		}
	}
}