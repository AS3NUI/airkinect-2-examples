package com.as3nui.nativeExtensions.air.kinect.examples.multiple {
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.KinectSettings;
	import com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint;
	import com.as3nui.nativeExtensions.air.kinect.data.User;
	import com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.DeviceEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;

	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Vector3D;

	public class MultipleDemo extends DemoBase {
		public static const KinectMaxDepthInFlash:uint = 200;

		private var device:Kinect;
		private var device2:Kinect;
		private var rgbBitmap:Bitmap;
		private var depthBitmap:Bitmap;

		private var rgbSkeletonContainer:Sprite;
		private var depthSkeletonContainer:Sprite;
		private var skeletonContainer:Sprite;

		override protected function startDemoImplementation():void {
			trace("[BasicDemo] startDemoImplementation");
			trace(Kinect.numDevices());
			if (Kinect.isSupported() && Kinect.numDevices() >=2) {

				device = Kinect.getDevice(1);
				device2 = Kinect.getDevice(0);

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
				device.addEventListener(CameraImageEvent.DEPTH_IMAGE_UPDATE, depthImageUpdateHandler, false, 0, true);

				var settings:KinectSettings = new KinectSettings();
				settings.depthEnabled = true;
				settings.depthShowUserColors = true;
				settings.skeletonEnabled = true;
				device.start(settings);

				settings = new KinectSettings();
				settings.rgbEnabled = true;
				device2.start(settings);
				device2.addEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler, false, 0, true);

				addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
			}
		}

		protected function kinectStartedHandler(event:DeviceEvent):void {
			trace("[BasicDemo] device started");
		}

		protected function kinectStoppedHandler(event:DeviceEvent):void {
			trace("[BasicDemo] device stopped");
		}

		override protected function stopDemoImplementation():void {
			removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			if (device != null) {
				device2.removeEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler);
				device.removeEventListener(CameraImageEvent.DEPTH_IMAGE_UPDATE, depthImageUpdateHandler);
				device.removeEventListener(DeviceEvent.STARTED, kinectStartedHandler);
				device.stop();
				device2.stop();
				device.removeEventListener(DeviceEvent.STOPPED, kinectStoppedHandler);
			}
		}

		protected function enterFrameHandler(event:Event):void {
			rgbSkeletonContainer.graphics.clear();
			depthSkeletonContainer.graphics.clear();
			skeletonContainer.removeChildren();

			drawDeviceSkeletons(device, 0, 400);
			drawDeviceSkeletons(device2, 400, 800);
		}

		private function drawDeviceSkeletons(device:Kinect, startX:int, endX:int):void {
			for each(var user:User in device.users) {
				if (user.hasSkeleton) {
					for each(var joint:SkeletonJoint in user.skeletonJoints) {
						rgbSkeletonContainer.graphics.beginFill(0xFF0000);
						rgbSkeletonContainer.graphics.drawCircle(joint.rgbPosition.x, joint.rgbPosition.y, 5);
						rgbSkeletonContainer.graphics.endFill();

						depthSkeletonContainer.graphics.beginFill(0xFF0000);
						depthSkeletonContainer.graphics.drawCircle(joint.depthPosition.x, joint.depthPosition.y, 5);
						depthSkeletonContainer.graphics.endFill();

						var color:uint = (joint.positionRelative.z / (KinectMaxDepthInFlash * 4)) * 255 << 16 | (1 - (joint.positionRelative.z / (KinectMaxDepthInFlash * 4))) * 255 << 8 | 0;

						var jointSprite:Sprite = createCircleForPosition(joint.positionRelative, color, startX, endX);
						skeletonContainer.addChild(jointSprite);
					}
				}
				//user center position
				var userCenterSprite:Sprite = createCircleForPosition(user.positionRelative, 0xFF0000, startX, endX);
				skeletonContainer.addChild(userCenterSprite);
			}
		}

		private function createCircleForPosition(positionRelative:Vector3D, color:uint, startX:uint, endX:uint):Sprite {
			var xPos:Number = (((positionRelative.x + 1) * .5) * (endX - startX)) + startX;
			var yPos:Number = (((positionRelative.y - 1) / -2) * (endX - startX)) + startX;
			var zPos:Number = positionRelative.z * KinectMaxDepthInFlash;

			var circle:Sprite = new Sprite();
			circle.graphics.beginFill(color);
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

		override protected function layout():void {
			if (depthBitmap != null) {
				depthBitmap.x = explicitWidth - depthBitmap.width;
				depthSkeletonContainer.x = depthBitmap.x;
			}
			if (root != null) {
				root.transform.perspectiveProjection.projectionCenter = new Point(explicitWidth * .5, explicitHeight * .5);
			}
		}
	}
}