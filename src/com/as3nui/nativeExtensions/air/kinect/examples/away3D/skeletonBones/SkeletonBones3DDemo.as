package com.as3nui.nativeExtensions.air.kinect.examples.away3D.skeletonBones
{
	
	import away3d.cameras.Camera3D;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.controllers.HoverController;
	
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.KinectSettings;
	import com.as3nui.nativeExtensions.air.kinect.constants.CameraResolution;
	import com.as3nui.nativeExtensions.air.kinect.constants.DeviceState;
	import com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint;
	import com.as3nui.nativeExtensions.air.kinect.data.User;
	import com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.DeviceEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.UserEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;
	import com.as3nui.nativeExtensions.air.kinect.recorder.KinectPlayer;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.geom.Vector3D;
	
	public class SkeletonBones3DDemo extends DemoBase
	{
		
		private var scene:Scene3D;
		private var view:View3D;
		
		private var cameraController:HoverController;
		
		//navigation variables
		private var _move:Boolean = false;
		private var _lastPanAngle:Number;
		private var _lastTiltAngle:Number;
		private var _lastMouseX:Number;
		private var _lastMouseY:Number;
		
		private var device:Kinect;
		private var player:KinectPlayer;
		
		private var rgbBitmap:Bitmap;
		private var rgbSkeletonContainer:Sprite;
		
		private var userViews:Vector.<SkeletonRenderer>;
		
		private var stageRef:Stage;
		
		override protected function startDemoImplementation():void
		{
			trace("[SkeletonBones3DDemo] Start Demo");
			stageRef = stage;
			
			scene = new Scene3D();
			
			userViews = new Vector.<SkeletonRenderer>();
			
			view = new View3D();
			view.antiAlias = 4;
			view.backgroundColor = 0xFFFFFF;
			view.scene = scene;
			addChild(view);
			
			cameraController = new HoverController(view.camera, null, 45, 20, 1000, -90);
			
			rgbBitmap = new Bitmap();
			addChild(rgbBitmap);
			
			rgbSkeletonContainer = new Sprite();
			addChild(rgbSkeletonContainer);
			
			var settings:KinectSettings = new KinectSettings();
			settings.rgbEnabled = true;
			settings.rgbResolution = CameraResolution.RESOLUTION_320_240;
			settings.rgbMirrored = false;
			settings.skeletonEnabled = true;
			settings.skeletonMirrored = false;
			
			player = new KinectPlayer();
			player.addEventListener(DeviceEvent.STARTED, kinectStartedHandler, false, 0, true);
			player.addEventListener(DeviceEvent.STOPPED, kinectStoppedHandler, false, 0, true);
			player.addEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler, false, 0, true);
			player.addEventListener(UserEvent.USERS_WITH_SKELETON_ADDED, usersWithSkeletonAddedHandler, false, 0, true);
			player.addEventListener(UserEvent.USERS_WITH_SKELETON_REMOVED, usersWithSkeletonRemovedHandler, false, 0, true);
			
			//simulate using a recording
			//player.playbackDirectoryUrl = File.documentsDirectory.resolvePath("export-mssdk").url;
			//splayer.start(settings);
			
			//use kinect when the player / simulator is not used
			if(player.state == DeviceState.STOPPED && Kinect.isSupported())
			{
				device = Kinect.getDevice();
				
				device.addEventListener(DeviceEvent.STARTED, kinectStartedHandler, false, 0, true);
				device.addEventListener(DeviceEvent.STOPPED, kinectStoppedHandler, false, 0, true);
				device.addEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler, false, 0, true);
				device.addEventListener(UserEvent.USERS_WITH_SKELETON_ADDED, usersWithSkeletonAddedHandler, false, 0, true);
				device.addEventListener(UserEvent.USERS_WITH_SKELETON_REMOVED, usersWithSkeletonRemovedHandler, false, 0, true);
				
				device.start(settings);
			}
			
			addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
			stageRef.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);
			stageRef.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);
		}
		
		private function onMouseDown(event:MouseEvent):void
		{
			_lastPanAngle = cameraController.panAngle;
			_lastTiltAngle = cameraController.tiltAngle;
			_lastMouseX = stage.mouseX;
			_lastMouseY = stage.mouseY;
			_move = true;
		}
		
		private function onMouseUp(event:MouseEvent):void
		{
			_move = false;
		}
		
		protected function rgbImageUpdateHandler(event:CameraImageEvent):void
		{
			rgbBitmap.bitmapData = event.imageData;
		}
		
		protected function kinectStartedHandler(event:DeviceEvent):void
		{
			if(event.target == device)
			{
				trace("[SkeletonBones3DDemo] Kinect started");
			}
			else
			{
				trace("[SkeletonBones3DDemo] Kinect Player started");
			}
		}
		
		protected function kinectStoppedHandler(event:DeviceEvent):void
		{
			if(event.target == player)
			{
				trace("[SkeletonBones3DDemo] Kinect stopped");
			}
			else
			{
				trace("[SkeletonBones3DDemo] Kinect Player stopped");
			}
		}
		
		protected function usersWithSkeletonAddedHandler(event:UserEvent):void
		{
			trace("[SkeletonBones3DDemo] User With Skeleton Added", event.users);
			for each(var user:User in event.users)
			{
				createViewForUser(user);
			}
		}
		
		private function createViewForUser(user:User):void
		{
			var userView:SkeletonRenderer = new SkeletonRenderer(user);
			userViews.push(userView);
			scene.addChild(userView);
			trace("added user view");
		}
		
		protected function usersWithSkeletonRemovedHandler(event:UserEvent):void
		{
			trace("[SkeletonBones3DDemo] User With Skeleton Removed", event.users);
			for each(var user:User in event.users)
			{
				destroyViewForUser(user);
			}
		}
		
		private function destroyViewForUser(user:User):void
		{
			var index:int = -1;
			for(var i:int = 0; i < userViews.length; i++)
			{
				if(userViews[i].user == user)
				{
					scene.removeChild(userViews[i]);
				}
			}
			if(index > -1)
				userViews.splice(index, 1);
		}
		
		protected function enterFrameHandler(event:Event):void
		{
			if(_move)
			{
				cameraController.panAngle = 0.3*(stage.mouseX - _lastMouseX) + _lastPanAngle;
				cameraController.tiltAngle = 0.3*(stage.mouseY - _lastMouseY) + _lastTiltAngle;
			}
			view.render();
			if(userViews != null)
			{
				for each(var userView:SkeletonRenderer in userViews)
				{
					userView.render();
				}
			}
			if(rgbSkeletonContainer != null)
			{
				rgbSkeletonContainer.graphics.clear();
				if(device != null)
				{
					drawUsers(device.usersWithSkeleton);
				}
				if(player != null)
				{
					drawUsers(player.users);
				}
			}
		}
		
		private function drawUsers(users:Vector.<User>):void
		{
			for each(var user:User in users)
			{
				drawRGBBone(user.leftHand, user.leftElbow);
				drawRGBBone(user.leftElbow, user.leftShoulder);
				drawRGBBone(user.leftShoulder, user.neck);
				
				drawRGBBone(user.rightHand, user.rightElbow);
				drawRGBBone(user.rightElbow, user.rightShoulder);
				drawRGBBone(user.rightShoulder, user.neck);
				
				drawRGBBone(user.head, user.neck);
				drawRGBBone(user.torso, user.neck);
				
				drawRGBBone(user.torso, user.leftHip);
				drawRGBBone(user.leftHip, user.leftKnee);
				drawRGBBone(user.leftKnee, user.leftFoot);
				
				drawRGBBone(user.torso, user.rightHip);
				drawRGBBone(user.rightHip, user.rightKnee);
				drawRGBBone(user.rightKnee, user.rightFoot);
				
				for each(var joint:SkeletonJoint in user.skeletonJoints)
				{
					rgbSkeletonContainer.graphics.lineStyle(2, 0xFFFFFF);
					rgbSkeletonContainer.graphics.beginFill(0xFF0000);
					rgbSkeletonContainer.graphics.drawCircle(joint.position.rgb.x, joint.position.rgb.y, 2);
					rgbSkeletonContainer.graphics.endFill();
				}
			}
		}
		
		private function drawRGBBone(from:SkeletonJoint, to:SkeletonJoint):void
		{
			rgbSkeletonContainer.graphics.lineStyle(3, 0xFF0000);
			rgbSkeletonContainer.graphics.moveTo(from.position.rgb.x, from.position.rgb.y);
			rgbSkeletonContainer.graphics.lineTo(to.position.rgb.x, to.position.rgb.y);
			rgbSkeletonContainer.graphics.lineStyle(0);
		}
		
		override protected function stopDemoImplementation():void
		{
			trace("[SkeletonBones3DDemo] Stop Demo");
			removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			stageRef.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stageRef.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			if(device != null)
			{
				device.removeEventListener(DeviceEvent.STARTED, kinectStartedHandler);
				device.removeEventListener(DeviceEvent.STOPPED, kinectStoppedHandler);
				device.removeEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler);
				device.removeEventListener(UserEvent.USERS_WITH_SKELETON_ADDED, usersWithSkeletonAddedHandler);
				device.removeEventListener(UserEvent.USERS_WITH_SKELETON_REMOVED, usersWithSkeletonRemovedHandler);
				device.stop();
			}
			if(player != null)
			{
				player.removeEventListener(DeviceEvent.STARTED, kinectStartedHandler);
				player.removeEventListener(DeviceEvent.STOPPED, kinectStoppedHandler);
				player.removeEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler);
				player.removeEventListener(UserEvent.USERS_WITH_SKELETON_ADDED, usersWithSkeletonAddedHandler);
				player.removeEventListener(UserEvent.USERS_WITH_SKELETON_REMOVED, usersWithSkeletonRemovedHandler);
				player.stop();
			}
			view.dispose();
		}
		
		override protected function layout():void
		{
			if(view != null)
			{
				view.width = explicitWidth;
				view.height = explicitHeight;
			}
		}
	}
}
import away3d.containers.ObjectContainer3D;
import away3d.entities.Mesh;
import away3d.materials.ColorMaterial;
import away3d.primitives.CylinderGeometry;

import com.as3nui.nativeExtensions.air.kinect.data.SkeletonBone;
import com.as3nui.nativeExtensions.air.kinect.data.User;

import flash.display.Sprite;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;

internal class SkeletonRenderer extends ObjectContainer3D
{
	
	public var user:User;
	
	private var rootView:BoneView;
	
	public function SkeletonRenderer(user:User)
	{
		this.user = user;
		
		rootView = createBoneView(SkeletonBone.SPINE, 0, 0);
		
		var spineView:BoneView = createBoneView(SkeletonBone.SPINE, 100, 0xff0000, rootView);
		var neckView:BoneView = createBoneView(SkeletonBone.NECK, 40, 0xff0000, spineView);
		
		var leftUpperArmView:BoneView = createBoneView(SkeletonBone.LEFT_UPPER_ARM, 100, 0xff0000, spineView);
		var leftLowerArmView:BoneView = createBoneView(SkeletonBone.LEFT_LOWER_ARM, 100, 0xff0000, leftUpperArmView);
		
		var rightUpperArmView:BoneView = createBoneView(SkeletonBone.RIGHT_UPPER_ARM, 100, 0xff0000, spineView);
		var rightLowerArmView:BoneView = createBoneView(SkeletonBone.RIGHT_LOWER_ARM, 100, 0xff0000, rightUpperArmView);
		
		var leftUpperLegView:BoneView = createBoneView(SkeletonBone.LEFT_UPPER_LEG, 100, 0xff0000, rootView);
		var leftLowerLegView:BoneView = createBoneView(SkeletonBone.LEFT_LOWER_LEG, 100, 0xff0000, leftUpperLegView);
		
		var rightUpperLegView:BoneView = createBoneView(SkeletonBone.RIGHT_UPPER_LEG, 100, 0xff0000, rootView);
		var rightLowerLegView:BoneView = createBoneView(SkeletonBone.RIGHT_LOWER_LEG, 100, 0xff0000, rightUpperLegView);
	}
	
	private function createBoneView(boneName:String, length:uint, color:uint, parentBone:BoneView = null):BoneView
	{
		var boneView:BoneView = new BoneView(boneName, length, color);
		boneView.name = boneName;
		if(parentBone)
		{
			boneView.parentBoneView = parentBone;
			boneView.parentBoneView.childBoneViews.push(boneView);
		}
		addChild(boneView);
		return boneView;
	}
	
	private function transformBoneAndChildBones(boneView:BoneView):void
	{
		var bone:SkeletonBone = user.getBoneByName(boneView.boneName);
		if(bone)
		{
			var m:Matrix3D = bone.orientation.absoluteOrientationMatrix.clone();
			if(m.determinant == 0) 
				m.identity();
			m.appendScale(1, -1, 1);
			applyTranslation(m, boneView);
			boneView.transform = m;
		}
		else
		{
			boneView.rotationX = 0;
		}
		for each(var childBoneView:BoneView in boneView.childBoneViews)
		{
			transformBoneAndChildBones(childBoneView);
		}
	}
	
	private function applyTranslation(m:Matrix3D, boneView:BoneView):void
	{
		if(boneView.parentBoneView != null && boneView.parentBoneView.transform != null)
		{
			var p:Vector3D = new Vector3D(0, boneView.parentBoneView.lenght, 0);
			p = boneView.parentBoneView.transform.transformVector(p);
			m.appendTranslation(p.x, p.y, p.z);
		}
	}
	
	public function render():void
	{
		this.x = user.torso.position.world.x * .2;
		this.y = user.torso.position.world.y * .2;
		this.z = user.torso.position.world.z * .2;
		
		transformBoneAndChildBones(rootView);
	}
}

internal class BoneView extends ObjectContainer3D
{
	
	private var _length:uint;
	
	public function get lenght():uint
	{
		return _length;
	}
	
	private var _boneName:String;
	
	public function get boneName():String
	{
		return _boneName;
	}
	
	public var framework:String;
	
	public var parentBoneView:BoneView;
	public var childBoneViews:Vector.<BoneView>;
	
	public function BoneView(boneName:String, length:uint, color:uint)
	{
		_length = length;
		_boneName = boneName;
		
		var m:Mesh = new Mesh(new CylinderGeometry(10, 10, length));
		m.material = new ColorMaterial(0xff0000);
		m.y = length * .5;
		addChild(m);
		
		childBoneViews = new Vector.<BoneView>();
	}
}