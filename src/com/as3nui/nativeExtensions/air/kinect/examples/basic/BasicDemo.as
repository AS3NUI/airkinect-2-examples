package com.as3nui.nativeExtensions.air.kinect.examples.basic {
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.KinectSettings;
	import com.as3nui.nativeExtensions.air.kinect.constants.CameraResolution;
	import com.as3nui.nativeExtensions.air.kinect.data.DeviceCapabilities;
	import com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint;
	import com.as3nui.nativeExtensions.air.kinect.data.User;
	import com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.DeviceErrorEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.DeviceEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.DeviceInfoEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;
	import com.as3nui.nativeExtensions.air.kinect.frameworks.openni.data.OpenNISkeletonJoint;
	import com.bit101.components.CheckBox;
	import com.bit101.components.InputText;
	import com.bit101.components.NumericStepper;
	import com.bit101.components.Text;
	import com.bit101.components.Window;
	import com.bit101.utils.MinimalConfigurator;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.utils.describeType;

	public class BasicDemo extends DemoBase {
		public static const KinectMaxDepthInFlash:uint = 200;

		private var device:Kinect;
		private var rgbBitmap:Bitmap;
		private var depthBitmap:Bitmap;

		private var rgbSkeletonContainer:Sprite;
		private var depthSkeletonContainer:Sprite;
		private var skeletonContainer:Sprite;

		public var statsWindow:Window;
		
		public var rgbMirrorCheckBox:CheckBox;
		public var depthMirrorCheckBox:CheckBox;
		public var skeletonMirrorCheckBox:CheckBox;
		public var nearModeCheckBox:CheckBox;
		public var seatedSkeletonCheckBox:CheckBox;
		public var chooseSkeletonsCheckBox:CheckBox;
		public var trackingIdsField:InputText;
		
		public var cameraElevationStepper:NumericStepper;
		public var deviceMessagesField:Text;
		
		private var chosenSkeletonId:int = -1;

		override protected function startDemoImplementation():void {
			trace("[BasicDemo] startDemoImplementation");
			if (Kinect.isSupported()) {
				device = Kinect.getDevice();

				rgbBitmap = new Bitmap();
				addChild(rgbBitmap);

				depthBitmap = new Bitmap();
				addChild(depthBitmap);

				rgbSkeletonContainer = new Sprite();
				addChild(rgbSkeletonContainer);

				depthSkeletonContainer = new Sprite();
				addChild(depthSkeletonContainer);

				skeletonContainer = new Sprite();
				addChild(skeletonContainer);

				device.addEventListener(DeviceEvent.STARTED, kinectStartedHandler, false, 0, true);
				device.addEventListener(DeviceEvent.STOPPED, kinectStoppedHandler, false, 0, true);
				device.addEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler, false, 0, true);
				device.addEventListener(CameraImageEvent.DEPTH_IMAGE_UPDATE, depthImageUpdateHandler, false, 0, true);
				device.addEventListener(DeviceInfoEvent.INFO, onDeviceInfo, false, 0, true);
				device.addEventListener(DeviceErrorEvent.ERROR, onDeviceError, false, 0, true);

				var settings:KinectSettings = new KinectSettings();
				settings.rgbEnabled = true;
				settings.rgbResolution = CameraResolution.RESOLUTION_320_240;
				settings.depthEnabled = true;
				settings.depthResolution = CameraResolution.RESOLUTION_320_240;
				settings.depthShowUserColors = true;
				settings.skeletonEnabled = true;

				device.start(settings);

				initUI(settings);

				addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
			}
		}

		private function onDeviceInfo(event:DeviceInfoEvent):void {
			deviceMessagesField.text += "INFO: " + event.message + "\n";
		}

		private function onDeviceError(event:DeviceErrorEvent):void {
			deviceMessagesField.text += "ERROR: " + event.message + "\n";
		}

		private function initUI(deviceSettings:KinectSettings):void {
			var config:MinimalConfigurator = new MinimalConfigurator(this);

			var mainLayout:XML = <comps>
				<Window title="Capabilities" id="capabilitiesWindow" x="250" y = "10" width="300" height="350" minimized="true" hasMinimizeButton="true">
					<VBox spacing="2" x="10" y="10"/>
				</Window>
				<Window title="Settings" id="statsWindow" x="560" y = "10" width="200" height="150" minimized="true" hasMinimizeButton="true">
					<HBox spacing="20" x = "10" y = "10">
						<VBox>
							<CheckBox label="RGB Mirror" id="rgbMirrorCheckBox" event="click:onChkClick"/>
							<CheckBox label="Depth Mirror" id="depthMirrorCheckBox" event="click:onChkClick"/>
							<CheckBox label="Skeleton Mirror" id="skeletonMirrorCheckBox" event="click:onChkClick"/>
						</VBox>
					</HBox>
				</Window>
				<Window title="Device Messages" id="deviceMessagesWindow" x="770" y = "10" width="200" height="350" minimized="false" hasMinimizeButton="true">
					<TextArea id="deviceMessagesField" width="200"  height="325" editable="false"/>
				</Window>
			</comps>;

			var deviceCapabilities:DeviceCapabilities = device.capabilities;
			var capability:String;
			for each(var capabilityXML:XML in describeType(deviceCapabilities)..accessor) {
				capability = capabilityXML.@name.toString();
				var value:String = deviceCapabilities[capability].toString();
				var lblXML:XML = <Label text={capability + " :: " + value}/>;
				mainLayout..Window.(@id == "capabilitiesWindow").VBox.appendChild(lblXML);
			}
			
			if(deviceCapabilities.hasNearModeSupport)
				mainLayout..Window.(@id == "statsWindow")..VBox.appendChild(<CheckBox label="Near Mode" id="nearModeCheckBox" event="click:onChkClick"/>);
			if(deviceCapabilities.hasSeatedSkeletonSupport)
				mainLayout..Window.(@id == "statsWindow")..VBox.appendChild(<CheckBox label="Seated Skeleton" id="seatedSkeletonCheckBox" event="click:onChkClick"/>);
			if(deviceCapabilities.hasChooseSkeletonsSupport)
				mainLayout..Window.(@id == "statsWindow")..VBox.appendChild(<CheckBox label="Choose Skeletons" id="chooseSkeletonsCheckBox" event="click:onChkClick"/>);
			if(deviceCapabilities.hasCameraElevationSupport)
				mainLayout..Window.(@id == "statsWindow")..VBox.appendChild(<NumericStepper id="cameraElevationStepper" minimum="-27" maximum="27" step="1" event="change:onStepperChange" />);
			
			config.parseXML(mainLayout);

			rgbMirrorCheckBox.selected = deviceSettings.rgbMirrored;
			depthMirrorCheckBox.selected = deviceSettings.depthMirrored;
			skeletonMirrorCheckBox.selected = deviceSettings.skeletonMirrored;
			
			if(nearModeCheckBox) nearModeCheckBox.selected = deviceSettings.nearModeEnabled;
			if(seatedSkeletonCheckBox) seatedSkeletonCheckBox.selected = deviceSettings.seatedSkeletonEnabled;

			layout();
		}

		public function onChkClick(event:MouseEvent):void {
			switch (event.target) {
				case rgbMirrorCheckBox:
					device.setRGBMirror(rgbMirrorCheckBox.selected);
					break;
				case depthMirrorCheckBox:
					device.setDepthMirror(depthMirrorCheckBox.selected);
					break;
				case skeletonMirrorCheckBox:
					device.setSkeletonMirror(skeletonMirrorCheckBox.selected);
					break;
				case nearModeCheckBox:
					device.setNearModeEnabled(nearModeCheckBox.selected);
					break;
				case seatedSkeletonCheckBox:
					device.setSeatedSkeletonEnabled(seatedSkeletonCheckBox.selected);
					break;
				case chooseSkeletonsCheckBox:
					device.setChooseSkeletonsEnabled(chooseSkeletonsCheckBox.selected);
					updateChosenSkeletonId(chosenSkeletonId);
					break;
			}
		}
		
		public function onStepperChange(event:Event):void {
			switch(event.target) {
				case cameraElevationStepper:
					device.cameraElevationAngle = cameraElevationStepper.value;
					break;
			}
		}

		protected function kinectStartedHandler(event:DeviceEvent):void {
			trace("[BasicDemo] device started");
			if(cameraElevationStepper != null)
				cameraElevationStepper.value = device.cameraElevationAngle;
		}

		protected function kinectStoppedHandler(event:DeviceEvent):void {
			trace("[BasicDemo] device stopped");
		}

		override protected function stopDemoImplementation():void {
			removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			if (device != null) {
				device.removeEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler);
				device.removeEventListener(CameraImageEvent.DEPTH_IMAGE_UPDATE, depthImageUpdateHandler);
				device.removeEventListener(DeviceEvent.STARTED, kinectStartedHandler);
				device.removeEventListener(DeviceInfoEvent.INFO, onDeviceInfo);
				device.removeEventListener(DeviceErrorEvent.ERROR, onDeviceError);
				device.stop();
				device.removeEventListener(DeviceEvent.STOPPED, kinectStoppedHandler);
			}
		}

		protected function enterFrameHandler(event:Event):void {
			rgbSkeletonContainer.graphics.clear();
			depthSkeletonContainer.graphics.clear();
			skeletonContainer.removeChildren();
			
			var closestUser:User;
			var closestUserSkeletonId:int = -1;

			for each(var user:User in device.users) {
				
				closestUser ||= user;
				if(user.position.world.z < closestUser.position.world.z) closestUser = user;
				
				if (user.hasSkeleton) 
				{
					
					for each(var joint:SkeletonJoint in user.skeletonJoints) {
						rgbSkeletonContainer.graphics.beginFill(0xFF0000, joint.positionConfidence);
						rgbSkeletonContainer.graphics.drawCircle(joint.position.rgb.x, joint.position.rgb.y, 5);
						rgbSkeletonContainer.graphics.endFill();

						depthSkeletonContainer.graphics.beginFill(0xFF0000, joint.positionConfidence);
						depthSkeletonContainer.graphics.drawCircle(joint.position.depth.x, joint.position.depth.y, 5);
						depthSkeletonContainer.graphics.endFill();

						var color:uint = (joint.position.worldRelative.z / (KinectMaxDepthInFlash * 4)) * 255 << 16 | (1 - (joint.position.worldRelative.z / (KinectMaxDepthInFlash * 4))) * 255 << 8 | 0;

						var jointSprite:Sprite = createCircleForPosition(joint.position.worldRelative, color, joint.positionConfidence);
						skeletonContainer.addChild(jointSprite);
					}
				}
				//user center position
				var userCenterSprite:Sprite = createCircleForPosition(user.position.worldRelative, 0xFF0000, 1);
				skeletonContainer.addChild(userCenterSprite);
			}
			
			if(closestUser)
			{
				closestUserSkeletonId = closestUser.trackingID;
			}
			
			if(closestUserSkeletonId != chosenSkeletonId)
			{
				updateChosenSkeletonId(closestUserSkeletonId);
			}
		}
		
		private function updateChosenSkeletonId(chosenSkeletonId:int):void
		{
			//trace("updateChosenSkeletonId(" + chosenSkeletonId + ")");
			this.chosenSkeletonId = chosenSkeletonId;
			if(chosenSkeletonId > -1)
			{
				if(device.capabilities.hasChooseSkeletonsSupport && device.settings.chooseSkeletonsEnabled)
				{
					//trace("choose skeleton: " + chosenSkeletonId);
					device.chooseSkeletons(Vector.<uint>([chosenSkeletonId]));
				}
			}
		}

		private function createCircleForPosition(positionRelative:Vector3D, color:uint, alpha:Number):Sprite
		{
			var xPos:Number = ((positionRelative.x + 1) * .5) * explicitWidth;
			var yPos:Number = ((positionRelative.y - 1) / -2) * explicitHeight;
			var zPos:Number = positionRelative.z * KinectMaxDepthInFlash;

			var circle:Sprite = new Sprite();
			circle.graphics.beginFill(color, alpha);
			circle.graphics.drawCircle(0, 0, 15);
			circle.graphics.endFill();
			circle.x = xPos;
			circle.y = yPos;
			circle.z = zPos;

			return circle;
		}

		protected function depthImageUpdateHandler(event:CameraImageEvent):void {
			depthBitmap.bitmapData = event.imageData;
			layout();
		}

		protected function rgbImageUpdateHandler(event:CameraImageEvent):void {
			rgbBitmap.bitmapData = event.imageData;
		}

		override protected function layout():void
		{
			if (depthBitmap != null)
			{
				depthBitmap.x = explicitWidth - depthBitmap.width;
				depthSkeletonContainer.x = depthBitmap.x;
			}
			if (root != null)
			{
				root.transform.perspectiveProjection.projectionCenter = new Point(explicitWidth * .5, explicitHeight * .5);
			}
		}
	}
}