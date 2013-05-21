package com.as3nui.nativeExtensions.air.kinect.examples.gripRelease {
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.KinectSettings;
	import com.as3nui.nativeExtensions.air.kinect.constants.CameraResolution;
	import com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;
	import com.as3nui.nativeExtensions.air.kinect.frameworks.mssdk.data.MSHand;
	import com.as3nui.nativeExtensions.air.kinect.frameworks.mssdk.events.MSHandEvent;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	
	public class GripReleaseExample extends DemoBase {
		
		private var device:Kinect;
		
		private var grippingHands:Vector.<MSHand>;
		
		[Embed(source="/assets/painted-ladies.png")] private static const Photo:Class;
		
		private var image:Sprite;
		private var depthBitmap:Bitmap;
		
		override protected function startDemoImplementation():void {
			if (Kinect.isSupported()) {
				device = Kinect.getDevice();
				
				depthBitmap = new Bitmap();
				addChild(depthBitmap);
				
				image = new Sprite();
				var logo:Bitmap = new Photo();
				logo.smoothing = true;
				logo.x = -.5 * logo.width;
				logo.y = -.5 * logo.height;
				image.addChild(logo);
				addChild(image);
				
				image.x = explicitWidth * .5;
				image.y = explicitHeight * .5;
				
				var settings:KinectSettings = new KinectSettings();
				settings.depthEnabled = true;
				settings.skeletonEnabled = true;
				
				grippingHands = new Vector.<MSHand>();
				
				device.addEventListener(CameraImageEvent.DEPTH_IMAGE_UPDATE, depthUpdateHandler, false, 0, true);
				device.addEventListener(MSHandEvent.GRIP, gripHandler, false, 0, true);
				device.addEventListener(MSHandEvent.GRIP_RELEASE, gripReleaseHandler, false, 0, true);
				addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
				
				device.start(settings);
			}
		}
		
		protected function depthUpdateHandler(event:CameraImageEvent):void{
			depthBitmap.bitmapData = event.imageData;
			depthBitmap.x = explicitWidth - depthBitmap.width;
		}
		
		protected function enterFrameHandler(event:Event):void {
			if(grippingHands.length > 0) {
				image.x = grippingHands[0].position.depthRelative.x * explicitWidth;
				image.y = grippingHands[0].position.depthRelative.y * explicitHeight;
			}
		}
		
		protected function gripHandler(event:MSHandEvent):void {
			grippingHands.push(event.hand);
		}
		
		protected function gripReleaseHandler(event:MSHandEvent):void {
			var index:int = grippingHands.indexOf(event.hand);
			if(index > -1) {
				grippingHands.splice(index, 1);
			}
		}
		
		override protected function stopDemoImplementation():void {
			if (device != null) {
				device.removeEventListener(MSHandEvent.GRIP, gripHandler);
				device.removeEventListener(MSHandEvent.GRIP_RELEASE, gripReleaseHandler);
				removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
				device.stop();
			}
		}
		
		override protected function layout():void {
		}
	}
}