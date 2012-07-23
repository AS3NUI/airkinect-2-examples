package com.as3nui.nativeExtensions.air.kinect.examples.away3D.riggedModel
{
	
	import away3d.animators.SkeletonAnimator;
	import away3d.animators.data.SkeletonAnimation;
	import away3d.animators.data.SkeletonAnimationState;
	import away3d.animators.skeleton.Skeleton;
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
		private var _skeleton:Skeleton;
		
		private var _bodyMaterial:TextureMaterial;
		private var _animationController:RiggedModelAnimationControllerByJointPosition;
		
		public function RiggedModel(user:User)
		{
			this.user = user;
			
			AssetLibrary.enableParser(RotatedMD5MeshParser);
			AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, assetCompleteHandler, false, 0, true);
			
			//TODO: check info at http://away3d.com/forum/viewthread/2851/ and get it working with the latest away3D release
			
			//you'll need a mesh in T-pose for rotation based rigging to work!
			AssetLibrary.load(new URLRequest("assets/characters/export/character.md5mesh"));
		}
		
		override public function dispose():void
		{
			AssetLibrary.removeEventListener(AssetEvent.ASSET_COMPLETE, assetCompleteHandler, false);
			super.dispose();
		}
		
		protected function assetCompleteHandler(event:AssetEvent):void
		{
			if(event.asset is Mesh)
				handleMesh(event.asset as Mesh);
			if(event.asset is Skeleton)
				handleSkeleton(event.asset as Skeleton);
			
			if(everythingIsLoaded())
				createAnimationController();	
		}
		
		private function handleMesh(mesh:Mesh):void
		{
			_mesh = mesh;
			_bodyMaterial = new TextureMaterial(new BitmapTexture(new BodyMaterial().bitmapData));
			_bodyMaterial.ambientColor = 0x101020;
			_bodyMaterial.ambient = 1;
			_mesh.material = _bodyMaterial;
			addChild(_mesh);
			
			_skeleton = (_mesh.animationState.animation as SkeletonAnimation).skeleton;
		}
		
		private function handleSkeleton(skeleton:Skeleton):void
		{
			//_skeleton = skeleton;
		}
		
		private function everythingIsLoaded():Boolean
		{
			return (_mesh != null && _skeleton != null);
		}
		
		private function createAnimationController():void
		{
			var jointMapping:Dictionary = createMappingForKinectJointsToMeshBones();
			
			//code commented below will be used for latest away3D release
			/*
			var skeletonAnimationNode:RiggedModelAnimationNode = new RiggedModelAnimationNode(user, jointMapping);
			var skeletonAnimationSet:SkeletonAnimationSet = new SkeletonAnimationSet(5);
			var skeletonAnimationState:SkeletonAnimationState = new SkeletonAnimationState(skeletonAnimationNode);
			skeletonAnimationSet.addState("airkinect", skeletonAnimationState);
			var animator:SkeletonAnimator = new SkeletonAnimator(skeletonAnimationSet, _skeleton, false);
			animator.play("airkinect");
			_mesh.animator = animator;
			*/
			
			_animationController = new RiggedModelAnimationControllerByJointPosition(user, jointMapping, SkeletonAnimationState(_mesh.animationState));
		}
		
		private function createMappingForKinectJointsToMeshBones():Dictionary
		{
			var jointMapping:Dictionary = new Dictionary();
			
			jointMapping[SkeletonJoint.HEAD] = _skeleton.jointIndexFromName("Head");
			jointMapping[SkeletonJoint.NECK] = _skeleton.jointIndexFromName("Neck");
			jointMapping[SkeletonJoint.TORSO] = _skeleton.jointIndexFromName("Spine");
			
			jointMapping[SkeletonJoint.RIGHT_SHOULDER] = _skeleton.jointIndexFromName("RightArm");
			jointMapping[SkeletonJoint.RIGHT_ELBOW] = _skeleton.jointIndexFromName("RightForeArm");
			jointMapping[SkeletonJoint.RIGHT_HAND] = _skeleton.jointIndexFromName("RightHand");
			
			jointMapping[SkeletonJoint.LEFT_SHOULDER] = _skeleton.jointIndexFromName("LeftArm");
			jointMapping[SkeletonJoint.LEFT_ELBOW] = _skeleton.jointIndexFromName("LeftForeArm");
			jointMapping[SkeletonJoint.LEFT_HAND] = _skeleton.jointIndexFromName("LeftHand");
			
			jointMapping[SkeletonJoint.RIGHT_HIP] = _skeleton.jointIndexFromName("RightUpLeg");
			jointMapping[SkeletonJoint.RIGHT_KNEE] = _skeleton.jointIndexFromName("RightLeg");
			jointMapping[SkeletonJoint.RIGHT_FOOT] = _skeleton.jointIndexFromName("RightFoot");
			
			jointMapping[SkeletonJoint.LEFT_HIP] = _skeleton.jointIndexFromName("LeftUpLeg");
			jointMapping[SkeletonJoint.LEFT_KNEE] = _skeleton.jointIndexFromName("LeftLeg");
			jointMapping[SkeletonJoint.LEFT_FOOT] = _skeleton.jointIndexFromName("LeftFoot");
			
			return jointMapping;
		}
	}
}