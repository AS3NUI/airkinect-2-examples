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
	import com.as3nui.nativeExtensions.air.kinect.frameworks.mssdk.data.MSSkeletonJoint;
	import com.as3nui.nativeExtensions.air.kinect.frameworks.mssdk.data.MSUser;
	import com.as3nui.nativeExtensions.air.kinect.frameworks.openni.data.OpenNISkeletonJoint;
	import com.as3nui.nativeExtensions.air.kinect.recorder.KinectPlayer;
	import com.as3nui.nativeExtensions.air.kinect.recorder.KinectRecorder;
	import com.bit101.components.PushButton;
	
	import flash.display.Bitmap;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	
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
		
		private var bonesContainer:Sprite;

		private var settings:KinectSettings;

		private var rootBoneView:BoneView;
		private var hasUserWithSkeleton:Boolean;
		
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
			
			bonesContainer = new Sprite();
			addChild(bonesContainer);
			
			//createMSSkeleton();
			createOpenNISkeleton();
			
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
		
		private function createMSSkeleton():void
		{
			rootBoneView = createBoneView('waist', 0, 0xff0000);
			
			var leftHipBoneView:BoneView = createBoneView('left_hip', 50, 0xff0000, rootBoneView);
			var leftKneeView:BoneView = createBoneView('left_knee', 100, 0xff0000, leftHipBoneView);
			var leftAnkleView:BoneView = createBoneView('left_ankle', 100, 0xff0000, leftKneeView);
			var leftFootView:BoneView = createBoneView('left_foot', 30, 0xff0000, leftAnkleView);
			
			var rightHipBoneView:BoneView = createBoneView('right_hip', 50, 0xff0000, rootBoneView);
			var rightKneeBoneView:BoneView = createBoneView('right_knee', 100, 0xff0000, rightHipBoneView);
			var rightAnkleBoneView:BoneView = createBoneView('right_ankle', 100, 0xff0000, rightKneeBoneView);
			var rightFootView:BoneView = createBoneView('right_foot', 30, 0xff0000, rightAnkleBoneView);
			
			var torsoBoneView:BoneView = createBoneView('torso', 50, 0xff0000, rootBoneView);
			var neckBoneView:BoneView = createBoneView('neck', 100, 0xff0000, torsoBoneView);
			var headBoneView:BoneView = createBoneView('head', 40, 0xff0000, neckBoneView);
			
			var leftShoulderView:BoneView = createBoneView('left_shoulder', 70, 0xff0000, neckBoneView);
			var leftElbowView:BoneView = createBoneView('left_elbow', 100, 0xff0000, leftShoulderView);
			var leftWristView:BoneView = createBoneView('left_wrist', 100, 0xff0000, leftElbowView);
			var leftHandView:BoneView = createBoneView('left_hand', 30, 0xff0000, leftWristView);
			
			var rightShoulderView:BoneView = createBoneView('right_shoulder', 70, 0xff0000, neckBoneView);
			var rightElbowView:BoneView = createBoneView('right_elbow', 100, 0xff0000, rightShoulderView);
			var rightWristView:BoneView = createBoneView('right_wrist', 100, 0xff0000, rightElbowView);
			var rightHandView:BoneView = createBoneView('right_hand', 30, 0xff0000, rightWristView);
		}
		
		private function createOpenNISkeleton():void
		{
			rootBoneView = createBoneView('torso', 0, 0xff0000);

			var leftHipBoneView:BoneView = createBoneView('left_hip', 50, 0xff00ff, rootBoneView);
			var leftKneeView:BoneView = createBoneView('left_knee', 100, 0xff00ff, leftHipBoneView);
			var leftFootView:BoneView = createBoneView('left_foot', 30, 0xff00ff, leftKneeView);
			
			var rightHipBoneView:BoneView = createBoneView('right_hip', 50, 0xff00ff, rootBoneView);
			var rightKneeBoneView:BoneView = createBoneView('right_knee', 100, 0xff00ff, rightHipBoneView);
			var rightFootView:BoneView = createBoneView('right_foot', 30, 0xff00ff, rightKneeBoneView);

			var neckBoneView:BoneView = createBoneView('neck', 100, 0xff0000, rootBoneView);
			var headBoneView:BoneView = createBoneView('head', 40, 0x00ff00, neckBoneView);
			
			var leftShoulderView:BoneView = createBoneView('left_shoulder', 70, 0x0000ff, neckBoneView);
			var leftElbowView:BoneView = createBoneView('left_elbow', 100, 0xffff00, leftShoulderView);
			var leftHandView:BoneView = createBoneView('left_hand', 30, 0x00ffff, leftElbowView);
			
			var rightShoulderView:BoneView = createBoneView('right_shoulder', 70, 0xff00ff, neckBoneView);
			var rightElbowView:BoneView = createBoneView('right_elbow', 100, 0xff00ff, rightShoulderView);
			var rightHandView:BoneView = createBoneView('right_hand', 30, 0xff00ff, rightElbowView);
		}
		
		private function createBoneView(jointName:String, length:uint, color:uint, parentBone:BoneView = null):BoneView
		{
			var boneView:BoneView = new BoneView(jointName, length, color);
			boneView.name = jointName;
			if(parentBone)
			{
				boneView.parentBoneView = parentBone;
				boneView.parentBoneView.childBoneViews.push(boneView);
			}
			bonesContainer.addChild(boneView);
			return boneView;
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
			bonesContainer.x = explicitWidth * .5;
			bonesContainer.y = explicitHeight * .5;
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
			hasUserWithSkeleton = false;
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
			bonesContainer.visible = hasUserWithSkeleton;
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
					hasUserWithSkeleton = true;
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
					
					if(user is MSUser)
						msTransformBoneAndChildBones(user as MSUser, rootBoneView);
					else
					{
						openNITransformSkeleton(user);
					}
				}
			}
		}
		
		private function openNITransformSkeleton(user:User):void
		{
			var torsoBoneView:BoneView = bonesContainer.getChildByName('torso') as BoneView;
			
			var leftHipBoneView:BoneView = bonesContainer.getChildByName('left_hip') as BoneView;
			var leftKneeView:BoneView = bonesContainer.getChildByName('left_knee') as BoneView;
			var leftFootView:BoneView = bonesContainer.getChildByName('left_foot') as BoneView;
			
			var rightHipBoneView:BoneView = bonesContainer.getChildByName('right_hip') as BoneView;
			var rightKneeBoneView:BoneView = bonesContainer.getChildByName('right_knee') as BoneView;
			var rightFootView:BoneView = bonesContainer.getChildByName('right_foot') as BoneView;
			
			var neckBoneView:BoneView = bonesContainer.getChildByName('neck') as BoneView;
			var headBoneView:BoneView = bonesContainer.getChildByName('head') as BoneView;
			
			var leftShoulderView:BoneView = bonesContainer.getChildByName('left_shoulder') as BoneView;
			var leftElbowView:BoneView = bonesContainer.getChildByName('left_elbow') as BoneView;
			var leftHandView:BoneView = bonesContainer.getChildByName('left_hand') as BoneView;
			
			var rightShoulderView:BoneView = bonesContainer.getChildByName('right_shoulder') as BoneView;
			var rightElbowView:BoneView = bonesContainer.getChildByName('right_elbow') as BoneView;
			var rightHandView:BoneView = bonesContainer.getChildByName('right_hand') as BoneView;
			
			var m:Matrix3D;
			
			m = new Matrix3D();
			m.appendRotation(180, new Vector3D(0, 0, 1));
			applyTranslation(m, user.getJointByName(torsoBoneView.skeletonJointName), torsoBoneView);
			torsoBoneView.transform.matrix3D = m;
			
			m = new Matrix3D();
			//m.appendRotation(180, new Vector3D(0, 0, 1));
			m.append((user.getJointByName(leftHipBoneView.skeletonJointName) as OpenNISkeletonJoint).nativeOrientation);
			applyTranslation(m, user.getJointByName(leftHipBoneView.skeletonJointName), leftHipBoneView);
			leftHipBoneView.transform.matrix3D = m;
			
			m = new Matrix3D();
			//m.appendRotation(180, new Vector3D(0, 0, 1));
			m.append((user.getJointByName(leftKneeView.skeletonJointName) as OpenNISkeletonJoint).nativeOrientation);
			applyTranslation(m, user.getJointByName(leftKneeView.skeletonJointName), leftKneeView);
			leftKneeView.transform.matrix3D = m;
			
			m = new Matrix3D();
			//m.appendRotation(180, new Vector3D(0, 0, 1));
			m.append((user.getJointByName(leftFootView.skeletonJointName) as OpenNISkeletonJoint).nativeOrientation);
			applyTranslation(m, user.getJointByName(leftFootView.skeletonJointName), leftFootView);
			leftFootView.transform.matrix3D = m;
			
			m = new Matrix3D();
			//m.appendRotation(-180, new Vector3D(0, 0, 1));
			m.append((user.getJointByName(rightHipBoneView.skeletonJointName) as OpenNISkeletonJoint).nativeOrientation);
			applyTranslation(m, user.getJointByName(rightHipBoneView.skeletonJointName), rightHipBoneView);
			rightHipBoneView.transform.matrix3D = m;
			
			m = new Matrix3D();
			//m.appendRotation(-180, new Vector3D(0, 0, 1));
			m.append((user.getJointByName(rightKneeBoneView.skeletonJointName) as OpenNISkeletonJoint).nativeOrientation);
			applyTranslation(m, user.getJointByName(rightKneeBoneView.skeletonJointName), rightKneeBoneView);
			rightKneeBoneView.transform.matrix3D = m;
			
			m = new Matrix3D();
			//m.appendRotation(-180, new Vector3D(0, 0, 1));
			m.append((user.getJointByName(rightFootView.skeletonJointName) as OpenNISkeletonJoint).nativeOrientation);
			applyTranslation(m, user.getJointByName(rightFootView.skeletonJointName), rightFootView);
			rightFootView.transform.matrix3D = m;
			
			m = new Matrix3D();
			m.appendRotation(180, new Vector3D(0, 0, 1));
			applyTranslation(m, user.getJointByName(neckBoneView.skeletonJointName), neckBoneView);
			neckBoneView.transform.matrix3D = m;
			
			m = new Matrix3D();
			m.appendRotation(180, new Vector3D(0, 0, 1));
			applyTranslation(m, user.getJointByName(headBoneView.skeletonJointName), headBoneView);
			headBoneView.transform.matrix3D = m;
			
			m = new Matrix3D();
			m.appendRotation(90, new Vector3D(0, 0, 1));
			m.append((user.getJointByName(leftShoulderView.skeletonJointName) as OpenNISkeletonJoint).nativeOrientation);
			applyTranslation(m, user.getJointByName(leftShoulderView.skeletonJointName), leftShoulderView);
			leftShoulderView.transform.matrix3D = m;
			
			m = new Matrix3D();
			m.appendRotation(90, new Vector3D(0, 0, 1));
			m.append((user.getJointByName(leftElbowView.skeletonJointName) as OpenNISkeletonJoint).nativeOrientation);
			applyTranslation(m, user.getJointByName(leftElbowView.skeletonJointName), leftElbowView);
			leftElbowView.transform.matrix3D = m;
			
			m = new Matrix3D();
			m.appendRotation(90, new Vector3D(0, 0, 1));
			m.append((user.getJointByName(leftHandView.skeletonJointName) as OpenNISkeletonJoint).nativeOrientation);
			applyTranslation(m, user.getJointByName(leftHandView.skeletonJointName), leftHandView);
			leftHandView.transform.matrix3D = m;
			
			m = new Matrix3D();
			m.appendRotation(-90, new Vector3D(0, 0, 1));
			m.append((user.getJointByName(rightShoulderView.skeletonJointName) as OpenNISkeletonJoint).nativeOrientation);
			applyTranslation(m, user.getJointByName(rightShoulderView.skeletonJointName), rightShoulderView);
			rightShoulderView.transform.matrix3D = m;
			
			m = new Matrix3D();
			m.appendRotation(-90, new Vector3D(0, 0, 1));
			m.append((user.getJointByName(rightElbowView.skeletonJointName) as OpenNISkeletonJoint).nativeOrientation);
			applyTranslation(m, user.getJointByName(rightElbowView.skeletonJointName), rightElbowView);
			rightElbowView.transform.matrix3D = m;
			
			m = new Matrix3D();
			m.appendRotation(-90, new Vector3D(0, 0, 1));
			m.append((user.getJointByName(rightHandView.skeletonJointName) as OpenNISkeletonJoint).nativeOrientation);
			applyTranslation(m, user.getJointByName(rightHandView.skeletonJointName), rightHandView);
			rightHandView.transform.matrix3D = m;
		}
		
		private function applyTranslation(m:Matrix3D, joint:SkeletonJoint, boneView:BoneView):void
		{
			if(boneView.parentBoneView != null && boneView.parentBoneView.transform.matrix3D != null)
			{
				var p:Vector3D = new Vector3D(0, boneView.parentBoneView.lenght, 0);
				p = boneView.parentBoneView.transform.matrix3D.transformVector(p);
				m.appendTranslation(p.x, p.y, p.z);
			}
			else
			{
				m.appendTranslation(joint.position.worldRelative.x * 320, joint.position.worldRelative.y * 240, joint.position.worldRelative.z);
			}
		}
		
		private function msTransformBoneAndChildBones(userWithSkeleton:MSUser, boneView:BoneView):void
		{
			var joint:MSSkeletonJoint = userWithSkeleton.getJointByName(boneView.skeletonJointName) as MSSkeletonJoint;
			if(joint)
			{
				var m:Matrix3D = joint.nativeAbsoluteRotationMatrix.clone();
				//TODO: scale the matrix in native code?
				m.appendScale(1, -1, 1);
				
				applyTranslation(m, joint, boneView);
				
				try
				{
					boneView.transform.matrix3D = m;
				}
				catch(error:Error)
				{
					trace(joint.name, error.message);
				}
				for each(var childBoneView:BoneView in boneView.childBoneViews)
				{
					msTransformBoneAndChildBones(userWithSkeleton, childBoneView);
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
import flash.display.Shape;

internal class BoneView extends Shape
{
	
	private var _length:uint;
	
	public function get lenght():uint
	{
		return _length;
	}
	
	private var _skeletonJointName:String;
	
	public function get skeletonJointName():String
	{
		return _skeletonJointName;
	}
	
	public var parentBoneView:BoneView;
	public var childBoneViews:Vector.<BoneView>;
	
	public function BoneView(skeletonJointName:String, length:uint, color:uint)
	{
		_length = length;
		_skeletonJointName = skeletonJointName;
		
		graphics.beginFill(color);
		graphics.drawRect(-10, 0, 20, length);
		graphics.endFill();
		
		childBoneViews = new Vector.<BoneView>();
	}
}