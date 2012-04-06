package com.as3nui.nativeExtensions.air.kinect.examples.away3D.riggedModel
{
	import away3d.animators.data.SkeletonAnimation;
	import away3d.animators.data.SkeletonAnimationState;
	import away3d.animators.skeleton.SkeletonJoint;
	import away3d.cameras.Camera3D;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.entities.Mesh;
	import away3d.events.AssetEvent;
	import away3d.library.AssetLibrary;
	import away3d.lights.PointLight;
	import away3d.materials.TextureMaterial;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.textures.BitmapTexture;
	
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.KinectSettings;
	import com.as3nui.nativeExtensions.air.kinect.constants.CameraResolution;
	import com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint;
	import com.as3nui.nativeExtensions.air.kinect.data.User;
	import com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.DeviceEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.UserEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;
	import com.derschmale.away3d.loading.RotatedMD5MeshParser;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.net.URLRequest;

	public class RiggedModelDemo extends DemoBase
	{
		
		[Embed(source="/assets/characters/export/character.jpg")]
		private var BodyMaterial:Class;
		
		private var scene:Scene3D;
		private var camera:Camera3D;
		private var view:View3D;
		private var mesh:Mesh;

		private var _bodyMaterial:TextureMaterial;
		
		
		private var _light:PointLight;
		private var _light2:PointLight;
		private var _light3:PointLight;
		
		private var animationController:RiggedModelAnimationController;
		
		private var device:Kinect;
		
		private var rgbBitmap:Bitmap;
		private var rgbSkeletonContainer:Sprite;
		
		override protected function startDemoImplementation():void
		{
			trace("[RiggedModelDemo] Start Demo");
			
			scene = new Scene3D();
			camera = new Camera3D();
			
			view = new View3D();
			view.antiAlias = 4;
			view.backgroundColor = 0xFFFFFF;
			view.scene = scene;
			view.camera = camera;
			addChild(view);
			
			AssetLibrary.enableParser(RotatedMD5MeshParser);
			AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, assetCompleteHandler, false, 0, true);
			
			//you'll need a mesh in T-pose for rotation based rigging to work!
			AssetLibrary.load(new URLRequest("assets/characters/export/character.md5mesh"));
		}
		
		protected function assetCompleteHandler(event:AssetEvent):void
		{
			trace("assetCompleteHandler");
			if (!(event.asset is Mesh)) return;
			
			trace("create mesh");
			
			mesh = Mesh(event.asset);
			
			camera.z = mesh.maxZ * -14;
			camera.y = mesh.maxY / 2;
			
			initLights();
			initMaterials();
			
			mesh.material = _bodyMaterial;
			
			scene.addChild(mesh);
			
			var i:uint = 0;
			for each(var skeletonJoint:away3d.animators.skeleton.SkeletonJoint in (mesh.animationState.animation as SkeletonAnimation).skeleton.joints)
			{
				trace(i, skeletonJoint.name, skeletonJoint.parentIndex);
				i++;
			}
			
			var jointMapping:Vector.<Number> = Vector.<Number>([
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("Head"), 			// XN_SKEL_HEAD
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("Neck"),			// XN_SKEL_NECK
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("Spine"),			// XN_SKEL_TORSO
				
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("LeftArm"), 		// XN_SKEL_LEFT_SHOULDER
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("LeftForeArm"),	// XN_SKEL_LEFT_ELBOW
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("LeftHand"),		// XN_SKEL_LEFT_HAND
				
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("RightArm"), 		// XN_SKEL_RIGHT_SHOULDER
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("RightForeArm"),	// XN_SKEL_RIGHT_ELBOW
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("RightHand"), 		// XN_SKEL_RIGHT_HAND
				
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("LeftUpLeg"),		// XN_SKEL_LEFT_HIP
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("LeftLeg"),		// XN_SKEL_LEFT_KNEE
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("LeftFoot"),		// XN_SKEL_LEFT_FOOT
				
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("RightUpLeg"),		// XN_SKEL_RIGHT_HIP
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("RightLeg"),		// XN_SKEL_RIGHT_KNEE
				(mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("RightFoot")		// XN_SKEL_RIGHT_FOOT
			]);
			
			jointMapping.fixed = true;
			
			if(Kinect.isSupported())
			{
				device = Kinect.getDevice();
				if(device.capabilities.hasJointOrientationConfidenceSupport)
				{
					animationController = new RiggedModelAnimationControllerByRotation(jointMapping, SkeletonAnimationState(mesh.animationState));
				}
				else
				{
					trace("[RiggedModelDemo] No Joint Orientation Support, fallback on positions");
					animationController = new RiggedModelAnimationControllerByPosition(jointMapping, SkeletonAnimationState(mesh.animationState));
				}
				
				rgbBitmap = new Bitmap();
				addChild(rgbBitmap);
				
				rgbSkeletonContainer = new Sprite();
				addChild(rgbSkeletonContainer);
				
				device.addEventListener(DeviceEvent.STARTED, kinectStartedHandler, false, 0, true);
				device.addEventListener(DeviceEvent.STOPPED, kinectStoppedHandler, false, 0, true);
				device.addEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler, false, 0, true);
				device.addEventListener(UserEvent.USERS_WITH_SKELETON_ADDED, usersWithSkeletonAddedHandler, false, 0, true);
				device.addEventListener(UserEvent.USERS_WITH_SKELETON_REMOVED, usersWithSkeletonRemovedHandler, false, 0, true);
				
				var settings:KinectSettings = new KinectSettings();
				settings.rgbEnabled = true;
				settings.rgbResolution = CameraResolution.RESOLUTION_320_240;
				settings.skeletonEnabled = true;
				
				trace("[RiggedModelDemo] Start Kinect");
				device.start(settings);
				
				addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
			}
		}
		
		protected function rgbImageUpdateHandler(event:CameraImageEvent):void
		{
			rgbBitmap.bitmapData = event.imageData;
		}
		
		protected function kinectStartedHandler(event:DeviceEvent):void
		{
			trace("[RiggedModelDemo] Kinect started");
		}
		
		protected function kinectStoppedHandler(event:DeviceEvent):void
		{
			trace("[RiggedModelDemo] Kinect stopped");
		}
		
		protected function usersWithSkeletonAddedHandler(event:UserEvent):void
		{
			trace("[RiggedModelDemo] User With Skeleton Added", event.users);
			if(animationController.kinectUser == null)
			{
				animationController.kinectUser = event.users[0];
			}
		}
		
		protected function usersWithSkeletonRemovedHandler(event:UserEvent):void
		{
			trace("[RiggedModelDemo] User With Skeleton Removed", event.users);
			for each(var removedUser:User in event.users)
			{
				if(removedUser == animationController.kinectUser)
				{
					animationController.kinectUser = null;
					break;
				}
			}
			if(device.usersWithSkeleton.length > 0)
			{
				animationController.kinectUser = device.usersWithSkeleton[0];
			}
		}
		
		private function initLights():void
		{
			_light = new PointLight(); // DirectionalLight();
			_light.x = -5000;
			_light.y = 1000;
			_light.z = 7000;
			_light.color = 0xff1111;
			_light2 = new PointLight(); // DirectionalLight();
			_light2.x = 5000;
			_light2.y = 1000;
			_light2.z = 7000;
			_light2.color = 0x1111ff;
			_light3 = new PointLight();
			_light3.x = 30;
			_light3.y = 200;
			_light3.z = -100;
			_light3.color = 0xffeedd;
		}
		
		private function initMaterials():void
		{
			var lightPicker:StaticLightPicker = new StaticLightPicker([ _light, _light2, _light3 ]);
			
			_bodyMaterial = new TextureMaterial(new BitmapTexture(new BodyMaterial().bitmapData));
			_bodyMaterial.lightPicker = lightPicker;
			_bodyMaterial.ambientColor = 0x101020;
			_bodyMaterial.ambient = 1;
		}
		
		protected function enterFrameHandler(event:Event):void
		{
			view.render();
			if(rgbSkeletonContainer != null && device != null)
			{
				rgbSkeletonContainer.graphics.clear();
				for each(var user:User in device.usersWithSkeleton)
				{
					drawRGBBone(user.leftHand, user.leftElbow);
					drawRGBBone(user.leftElbow, user.leftShoulder);
					drawRGBBone(user.leftShoulder, user.neck);
					drawRGBBone(user.leftShoulder, user.torso);
					
					drawRGBBone(user.rightHand, user.rightElbow);
					drawRGBBone(user.rightElbow, user.rightShoulder);
					drawRGBBone(user.rightShoulder, user.neck);
					drawRGBBone(user.rightShoulder, user.torso);
					
					drawRGBBone(user.head, user.neck);
					
					drawRGBBone(user.torso, user.leftHip);
					drawRGBBone(user.leftHip, user.leftKnee);
					drawRGBBone(user.leftKnee, user.leftFoot);
					
					drawRGBBone(user.torso, user.rightHip);
					drawRGBBone(user.rightHip, user.rightKnee);
					drawRGBBone(user.rightKnee, user.rightFoot);
					
					for each(var joint:com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint in user.skeletonJoints)
					{
						rgbSkeletonContainer.graphics.lineStyle(2, 0xFFFFFF);
						rgbSkeletonContainer.graphics.beginFill(0xFF0000);
						rgbSkeletonContainer.graphics.drawCircle(joint.rgbPosition.x, joint.rgbPosition.y, 2);
						rgbSkeletonContainer.graphics.endFill();
					}
				}
			}
		}
		
		private function drawRGBBone(from:com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint, to:com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint):void
		{
			rgbSkeletonContainer.graphics.lineStyle(3, 0xFF0000);
			rgbSkeletonContainer.graphics.moveTo(from.rgbPosition.x, from.rgbPosition.y);
			rgbSkeletonContainer.graphics.lineTo(to.rgbPosition.x, to.rgbPosition.y);
			rgbSkeletonContainer.graphics.lineStyle(0);
		}
		
		override protected function stopDemoImplementation():void
		{
			trace("[RiggedModelDemo] Stop Demo");
			AssetLibrary.removeEventListener(AssetEvent.ASSET_COMPLETE, assetCompleteHandler);
			removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			if(device != null)
			{
				device.removeEventListener(DeviceEvent.STARTED, kinectStartedHandler);
				device.removeEventListener(DeviceEvent.STOPPED, kinectStoppedHandler);
				device.removeEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler);
				device.removeEventListener(UserEvent.USERS_WITH_SKELETON_ADDED, usersWithSkeletonAddedHandler);
				device.removeEventListener(UserEvent.USERS_WITH_SKELETON_REMOVED, usersWithSkeletonRemovedHandler);
				device.stop();
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