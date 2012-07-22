package com.as3nui.nativeExtensions.air.kinect.examples.away3D.riggedModel
{
	import away3d.animators.data.SkeletonAnimation;
	import away3d.animators.data.SkeletonAnimationState;
	import away3d.animators.skeleton.SkeletonJoint;
	import away3d.containers.ObjectContainer3D;
	import away3d.entities.Mesh;
	import away3d.events.AssetEvent;
	import away3d.library.AssetLibrary;
	import away3d.materials.TextureMaterial;
	import away3d.textures.BitmapTexture;
	
	import com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint;
	import com.as3nui.nativeExtensions.air.kinect.data.User;
	import com.derschmale.away3d.loading.RotatedMD5MeshParser;
	
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	
	public class RiggedModel extends ObjectContainer3D
	{
		
		[Embed(source="/assets/characters/export/character.jpg")]
		private var BodyMaterial:Class;
		
		public var user:User;
		
		private var _mesh:Mesh;
		private var _bodyMaterial:TextureMaterial;
		
		private var _animationController:RiggedModelAnimationController;
		
		public function RiggedModel(user:User)
		{
			this.user = user;
			
			AssetLibrary.enableParser(RotatedMD5MeshParser);
			AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, assetCompleteHandler, false, 0, true);
			
			//you'll need a mesh in T-pose for rotation based rigging to work!
			AssetLibrary.load(new URLRequest("assets/characters/export/character.md5mesh"));
			
			
			//animationController = new RiggedModelAnimationControllerByJointPosition(jointMapping, SkeletonAnimationState(mesh.animationState));
		}
		
		override public function dispose():void
		{
			AssetLibrary.removeEventListener(AssetEvent.ASSET_COMPLETE, assetCompleteHandler, false);
			super.dispose();
		}
		
		protected function assetCompleteHandler(event:AssetEvent):void
		{
			if (!(event.asset is Mesh)) return;
			
			_mesh = Mesh(event.asset);
			
			trace(_mesh.maxX, _mesh.maxY, _mesh.maxZ);
			
			
			_bodyMaterial = new TextureMaterial(new BitmapTexture(new BodyMaterial().bitmapData));
			//_bodyMaterial.lightPicker = lightPicker;
			_bodyMaterial.ambientColor = 0x101020;
			_bodyMaterial.ambient = 1;
			
			_mesh.material = _bodyMaterial;
			
			addChild(_mesh);
			
			//traceMeshSkeletonJoints();
			
			var jointMapping:Dictionary = createJointMapping();
			
			_animationController = new RiggedModelAnimationControllerByJointPosition(user, jointMapping, SkeletonAnimationState(_mesh.animationState));
		}
		
		private function traceMeshSkeletonJoints():void
		{
			var i:uint = 0;
			for each(var skeletonJoint:away3d.animators.skeleton.SkeletonJoint in (_mesh.animationState.animation as SkeletonAnimation).skeleton.joints)
			{
				trace(i, skeletonJoint.name, skeletonJoint.parentIndex);
				i++;
			}
		}
		
		private function createJointMapping():Dictionary
		{
			var jointMapping:Dictionary = new Dictionary();
			jointMapping[com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.HEAD] = (_mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("Head");
			jointMapping[com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.NECK] = (_mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("Neck");
			jointMapping[com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.TORSO] = 	(_mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("Spine");
			
			jointMapping[com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_SHOULDER] = (_mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("RightArm");
			jointMapping[com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_ELBOW] = (_mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("RightForeArm");
			jointMapping[com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_HAND] = (_mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("RightHand");
			
			jointMapping[com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_SHOULDER] = (_mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("LeftArm");
			jointMapping[com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_ELBOW] = (_mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("LeftForeArm");
			jointMapping[com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_HAND] = (_mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("LeftHand");
			
			jointMapping[com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_HIP] = (_mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("RightUpLeg");
			jointMapping[com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_KNEE] = (_mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("RightLeg");
			jointMapping[com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_FOOT] = (_mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("RightFoot");
			
			jointMapping[com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_HIP] = (_mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("LeftUpLeg");
			jointMapping[com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_KNEE] = (_mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("LeftLeg");
			jointMapping[com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_FOOT] = (_mesh.animationState.animation as SkeletonAnimation).skeleton.jointIndexFromName("LeftFoot");
			return jointMapping;
		}
	}
}