package com.as3nui.nativeExtensions.air.kinect.examples.record
{
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.KinectSettings;
	import com.as3nui.nativeExtensions.air.kinect.constants.CameraResolution;
	import com.as3nui.nativeExtensions.air.kinect.constants.DeviceState;
	import com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint;
	import com.as3nui.nativeExtensions.air.kinect.data.User;
	import com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.DeviceEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;
	import com.as3nui.nativeExtensions.air.kinect.recorder.KinectPlayer;
	import com.as3nui.nativeExtensions.air.kinect.recorder.KinectRecorder;
	import com.bit101.components.PushButton;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	
	public class RecordAndPlayBackDemo extends DemoBase
	{
		
		private var recorder:KinectRecorder;
		private var player:KinectPlayer;
		
		private var recordingButton:PushButton;
		private var playbackButton:PushButton;
		
		private var device:Kinect;
		private var rgb:Bitmap;
		private var depth:Bitmap;
		private var rgbSkeletonContainer:Sprite;
		private var depthSkeletonContainer:Sprite;

		private var settings:KinectSettings;
		
		public function RecordAndPlayBackDemo()
		{
			super();
			
			recorder = new KinectRecorder();
			
			player = new KinectPlayer();
			
			player.addEventListener(DeviceEvent.STARTED, playerStartedHandler, false, 0, true);
			player.addEventListener(DeviceEvent.STOPPED, playerStoppedHandler, false, 0, true);
			
			player.addEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbHandler, false, 0, true);
			player.addEventListener(CameraImageEvent.DEPTH_IMAGE_UPDATE, depthHandler, false, 0, true);
			
			recordingButton = new PushButton(this, 230, 10, "record", recordHandler);
			recordingButton.toggle = true;
			
			playbackButton = new PushButton(this, 230, 30, "playback", playbackHandler);
			playbackButton.toggle = true;
		}
		
		override protected function startDemoImplementation():void 
		{
			trace("[RecordAndPlayBackDemo] startDemoImplementation");
			
			rgb = new Bitmap();
			addChild(rgb);
			
			depth = new Bitmap();
			depth.x = 320;
			addChild(depth);
			
			rgbSkeletonContainer = new Sprite();
			addChild(rgbSkeletonContainer);
			
			depthSkeletonContainer = new Sprite();
			depthSkeletonContainer.x = depth.x;
			addChild(depthSkeletonContainer);
			
			settings = new KinectSettings();
			settings.rgbEnabled = true;
			settings.rgbResolution = CameraResolution.RESOLUTION_320_240;
			settings.depthEnabled = true;
			settings.depthResolution = CameraResolution.RESOLUTION_320_240;
			settings.skeletonEnabled = true;
			settings.depthShowUserColors = true;
			
			if(Kinect.isSupported()) 
			{
				recordingButton.enabled = true;
				
				device = Kinect.getDevice();
				
				device.addEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbHandler, false, 0, true);
				device.addEventListener(CameraImageEvent.DEPTH_IMAGE_UPDATE, depthHandler, false, 0, true);
				
				device.start(settings);
			}
			else
			{
				recordingButton.enabled = false;
			}
			
			addChild(recordingButton);
			addChild(playbackButton);
			
			addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
		}
		
		override protected function stopDemoImplementation():void
		{
			trace("[RecordAndPlayBackDemo] stopDemoImplementation");
			if(device)
			{
				device.removeEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbHandler, false);
				device.removeEventListener(CameraImageEvent.DEPTH_IMAGE_UPDATE, depthHandler, false);
				device.stop();
			}
			
			recorder.stopRecording();
			
			removeEventListener(Event.ENTER_FRAME, enterFrameHandler, false);
		}
		
		override protected function layout():void
		{
			if(root)
			{
				root.transform.perspectiveProjection.projectionCenter = new Point(explicitWidth * .5, explicitHeight * .5);
			}
		}
		
		protected function playerStartedHandler(event:Event):void
		{
			trace("player started");
			if(device)
			{
				device.removeEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbHandler, false);
				device.removeEventListener(CameraImageEvent.DEPTH_IMAGE_UPDATE, depthHandler, false);
			}
		}
		
		protected function playerStoppedHandler(event:Event):void
		{
			trace("player stopped");
			if(device)
			{
				device.addEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbHandler, false, 0, true);
				device.addEventListener(CameraImageEvent.DEPTH_IMAGE_UPDATE, depthHandler, false, 0, true);
			}
		}
		
		protected function enterFrameHandler(event:Event):void
		{
			if(player.state == DeviceState.STARTED)
			{
				drawUsers(player.users);
			}
			else
			{
				if(device)
				{
					drawUsers(device.users);
				}
			}
		}
		
		private function drawUsers(users:Vector.<User>):void
		{
			rgbSkeletonContainer.graphics.clear();
			depthSkeletonContainer.graphics.clear();
			
			for each(var user:User in users)
			{
				rgbSkeletonContainer.graphics.beginFill(0x0000ff);
				rgbSkeletonContainer.graphics.drawCircle(user.position.rgb.x, user.position.rgb.y, 20);
				rgbSkeletonContainer.graphics.endFill();
				
				depthSkeletonContainer.graphics.beginFill(0x0000ff);
				depthSkeletonContainer.graphics.drawCircle(user.position.depth.x, user.position.depth.y, 20);
				depthSkeletonContainer.graphics.endFill();
				
				if(user.hasSkeleton)
				{
					var joint:SkeletonJoint;
					for each(joint in user.skeletonJoints)
					{
						rgbSkeletonContainer.graphics.lineStyle(2, 0xff0000);
						rgbSkeletonContainer.graphics.beginFill((joint.name.indexOf("left") == 0) ? 0xff0000 : 0xffffff);
						rgbSkeletonContainer.graphics.drawCircle(joint.position.rgb.x, joint.position.rgb.y, 5);
						rgbSkeletonContainer.graphics.endFill();
						rgbSkeletonContainer.graphics.lineStyle(0);
						
						depthSkeletonContainer.graphics.lineStyle(2, 0xff0000);
						depthSkeletonContainer.graphics.beginFill((joint.name.indexOf("left") == 0) ? 0xff0000 : 0xffffff);
						depthSkeletonContainer.graphics.drawCircle(joint.position.depth.x, joint.position.depth.y, 5);
						depthSkeletonContainer.graphics.endFill();
						depthSkeletonContainer.graphics.lineStyle(0);
					}
				}
			}
		}
		
		protected function recordHandler(event:Event):void
		{
			if(recordingButton.selected)
			{
				recorder.startRecording(device);
			}
			else
			{
				recorder.stopRecording();
			}
			trace(recordingButton.selected);
		}
		
		protected function playbackHandler(event:Event):void
		{
			if(playbackButton.selected)
			{
				player.start(settings);
			}
			else
			{
				player.stop();
			}
		}
		
		protected function rgbHandler(event:CameraImageEvent):void
		{
			rgb.bitmapData = event.imageData;
		}
		
		protected function depthHandler(event:CameraImageEvent):void
		{
			depth.bitmapData = event.imageData;
		}
	}
}