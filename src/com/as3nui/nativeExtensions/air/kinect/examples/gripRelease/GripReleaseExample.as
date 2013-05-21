package com.as3nui.nativeExtensions.air.kinect.examples.gripRelease {
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.KinectSettings;
	import com.as3nui.nativeExtensions.air.kinect.constants.CameraResolution;
	import com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint;
	import com.as3nui.nativeExtensions.air.kinect.data.User;
	import com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;
	import com.as3nui.nativeExtensions.air.kinect.frameworks.mssdk.data.MSHand;
	import com.as3nui.nativeExtensions.air.kinect.frameworks.mssdk.events.MSHandEvent;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	
	public class GripReleaseExample extends DemoBase {
		
		private var device:Kinect;
		
		private var grippingHands:Vector.<MSHand>;
		
		[Embed(source="/assets/painted-ladies.png")] private static const Photo:Class;
		[Embed(source="/assets/hand-normal.png")] private static const HandNormal:Class;
		[Embed(source="/assets/hand-grab.png")] private static const HandGrab:Class;
		
		private var image:Sprite;
		private var depthBitmap:Bitmap;
		
		private var handCursor:Sprite;
		private var handNormal:Bitmap;
		private var handGrab:Bitmap;
		
		override protected function startDemoImplementation():void {
			if (Kinect.isSupported()) {
				device = Kinect.getDevice();
				
				depthBitmap = new Bitmap();
				addChild(depthBitmap);
				
				image = new Sprite();
				var photo:Bitmap = new Photo();
				photo.smoothing = true;
				photo.x = -.5 * photo.width;
				photo.y = -.5 * photo.height;
				image.addChild(photo);
				addChild(image);
				
				handCursor = new Sprite();
				handCursor.mouseChildren = false;
				handCursor.filters = [
					new GlowFilter(0x000000, 1, 4, 4, 20, 3),
					new DropShadowFilter(10, 90, 0x000000, 1, 10, 10, 0.4, 1)
				];
				
				handNormal = new HandNormal();
				handNormal.x = -.5 * handNormal.width;
				handNormal.y = -.5 * handNormal.height;
				handNormal.visible = false;
				handCursor.addChild(handNormal);
				
				handGrab = new HandGrab();
				handGrab.x = -.5 * handGrab.width;
				handGrab.y = -.5 * handGrab.height;
				handGrab.visible = false;
				handCursor.addChild(handGrab);
				
				addChild(handCursor);
				
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
			var activeHand:SkeletonJoint;
			for each(var user:User in device.usersWithSkeleton) {
				if(!activeHand) activeHand = user.leftHand;
				if(user.leftHand.position.worldRelative.z < activeHand.position.worldRelative.z) {
					activeHand = user.leftHand;
				}
				if(user.rightHand.position.worldRelative.z < activeHand.position.worldRelative.z) {
					activeHand = user.rightHand;
				}
			}
			
			if(grippingHands.length > 0) {
				activeHand = grippingHands[0];
				image.x = grippingHands[0].position.depthRelative.x * explicitWidth;
				image.y = grippingHands[0].position.depthRelative.y * explicitHeight;
			}
			
			if(activeHand) {
				handCursor.scaleX = (activeHand.name == SkeletonJoint.LEFT_HAND) ? 1 : -1;
				handCursor.x = activeHand.position.depthRelative.x * explicitWidth;
				handCursor.y = activeHand.position.depthRelative.y * explicitHeight;
				handCursor.visible = true;
				handNormal.visible = (grippingHands.length == 0);
				handGrab.visible = !handNormal.visible;
			} else {
				handCursor.visible = false;
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