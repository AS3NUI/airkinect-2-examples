package com.as3nui.nativeExtensions.air.kinect.examples.away3D.riggedModel
{
	import away3d.animators.data.SkeletonAnimation;
	import away3d.animators.data.SkeletonAnimationState;
	import away3d.animators.skeleton.JointPose;
	import away3d.animators.skeleton.Skeleton;
	import away3d.animators.skeleton.SkeletonJoint;
	import away3d.arcane;
	import away3d.core.math.Quaternion;
	
	import com.as3nui.nativeExtensions.air.kinect.data.SkeletonBone;
	import com.derschmale.data.ObjectPool;
	import com.derschmale.openni.XnSkeletonJoint;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	public class RiggedModelAnimationControllerByBoneOrientation extends RiggedModelAnimationController
	{
		private static const NUM_TRACKED_JOINTS : int = 15;
		
		private var _jointMapping : Vector.<Number>;
		private var _skeleton : away3d.animators.skeleton.Skeleton;
		private var _globalMatrices : Vector.<Matrix3D>;
		private var _globalWisdom : Vector.<Boolean>;
		private var _localPoses : Vector.<JointPose>;
		private var _globalPoses : Vector.<JointPose>;
		private var _bindPoses : Vector.<Matrix3D>;
		private var _bindPoseOrientations : Vector.<Vector3D>;
		private var _bindShoulderOrientation : Vector3D;
		private var _bindSpineOrientation : Vector3D;
		private var _jointSmoothing : Number = .1;
		private var _posSmoothing : Number = .8;
		private var _trackingCenter : Vector3D;
		private var _trackScale : Number = .1;
		private var _quaternionPool:ObjectPool;
		private var _vector3DPool:ObjectPool;
		private var _skeletonAnimationState : SkeletonAnimationState;
		
		private var _rootJoint:SkeletonJoint;
		private var _rootJointMapIndex:int = -1;
		
		public function RiggedModelAnimationControllerByBoneOrientation(jointMapping : Vector.<Number>, target : SkeletonAnimationState)
		{
			super();
			_quaternionPool = ObjectPool.getGlobalPool(Quaternion);
			_vector3DPool = ObjectPool.getGlobalPool(Vector3D);
			_jointMapping = jointMapping;
			
			_trackingCenter = new Vector3D();
			_skeletonAnimationState = target;
			
			SkeletonAnimationState(target).arcane::globalInput = true;
			
			initSkeleton();
			initBindPoseOrientations();
			
			start();
		}
		
		override protected function updateAnimation(realDT : Number, scaledDT : Number) : void
		{
			if(kinectUser != null)
			{
				updatePose();
			}
		}
		
		private function initSkeleton() : void
		{
			var joint:SkeletonJoint;
			var q1 : Quaternion = Quaternion(_quaternionPool.alloc()),
				q2 : Quaternion = Quaternion(_quaternionPool.alloc());
			var bind : Matrix3D = new Matrix3D();
			var parentBind : Matrix3D = new Matrix3D();
			
			_skeleton = SkeletonAnimation(_skeletonAnimationState.animation).skeleton;
			
			_localPoses = new Vector.<JointPose>(_skeleton.numJoints, true);
			_globalPoses = new Vector.<JointPose>(_skeleton.numJoints, true);
			_globalWisdom = new Vector.<Boolean>(_skeleton.numJoints, true);
			_bindPoses = new Vector.<Matrix3D>(_skeleton.numJoints, true);
			_globalMatrices = new Vector.<Matrix3D>(_skeleton.numJoints, true);
			
			for (var i : int = 0; i < _skeleton.numJoints; ++i)
			{
				// if index is in joint map, we know its global orientation
				joint = _skeleton.joints[i];
				_localPoses[i] = new JointPose();
				_globalPoses[i] = new JointPose();
				_globalPoses[i].orientation = new Quaternion();
				_globalPoses[i].translation = new Vector3D();
				bind = new Matrix3D(joint.inverseBindPose);
				bind.invert();
				_bindPoses[i] = bind;
				
				_localPoses[i].orientation = new Quaternion();
				if (joint.parentIndex < 0)
				{
					_rootJointMapIndex = i;
					_rootJoint = joint;
					_localPoses[i].orientation.fromMatrix(bind);
					_localPoses[i].translation = bind.position;
				}
				else 
				{
					parentBind.rawData = _skeleton.joints[joint.parentIndex].inverseBindPose;
					
					q1.fromMatrix(parentBind);
					q1.normalize();
					q2.fromMatrix(bind);
					q2.normalize();
					_localPoses[i].orientation.multiply(q1, q2);
					_localPoses[i].translation = parentBind.transformVector(bind.position);
				}
			}
			
			_quaternionPool.free(q1);
			_quaternionPool.free(q2);
		}
		
		private function initBindPoseOrientations() : void
		{
			_bindPoseOrientations = new Vector.<Vector3D>(NUM_TRACKED_JOINTS, true);
			
			_bindShoulderOrientation = new Vector3D();
			_bindSpineOrientation = new Vector3D();
			getSimpleBindOrientation(XnSkeletonJoint.LEFT_SHOULDER, XnSkeletonJoint.RIGHT_SHOULDER, _bindShoulderOrientation);
			getSimpleBindOrientation(XnSkeletonJoint.TORSO, XnSkeletonJoint.NECK, _bindSpineOrientation);
			
			getSimpleBindOrientation(XnSkeletonJoint.NECK, XnSkeletonJoint.HEAD);
			getSimpleBindOrientation(XnSkeletonJoint.LEFT_SHOULDER, XnSkeletonJoint.LEFT_ELBOW);
			getSimpleBindOrientation(XnSkeletonJoint.LEFT_ELBOW, XnSkeletonJoint.LEFT_HAND);
			getSimpleBindOrientation(XnSkeletonJoint.RIGHT_SHOULDER, XnSkeletonJoint.RIGHT_ELBOW);
			getSimpleBindOrientation(XnSkeletonJoint.RIGHT_ELBOW, XnSkeletonJoint.RIGHT_HAND);
			getSimpleBindOrientation(XnSkeletonJoint.LEFT_HIP, XnSkeletonJoint.LEFT_KNEE);
			getSimpleBindOrientation(XnSkeletonJoint.LEFT_KNEE, XnSkeletonJoint.LEFT_FOOT);
			getSimpleBindOrientation(XnSkeletonJoint.RIGHT_HIP, XnSkeletonJoint.RIGHT_KNEE);
			getSimpleBindOrientation(XnSkeletonJoint.RIGHT_KNEE, XnSkeletonJoint.RIGHT_FOOT);
		}
		
		private function getSimpleBindOrientation(src : int, tgt : int, storeVec : Vector3D = null) : void
		{
			var pos1 : Vector3D;
			var pos2 : Vector3D;
			var mapIndex1 : int = _jointMapping[src];
			var mapIndex2 : int = _jointMapping[tgt];
			var mtx : Matrix3D = new Matrix3D();
			
			if (mapIndex1 < 0 || mapIndex2 < 0) return;
			
			pos1 = _bindPoses[mapIndex1].position;
			pos2 = _bindPoses[mapIndex2].position;
			
			if (!storeVec)
				(_bindPoseOrientations[src] = pos2.subtract(pos1)).normalize();
			else {
				storeVec.x = pos2.x - pos1.x;
				storeVec.y = pos2.y - pos1.y;
				storeVec.z = pos2.z - pos1.z;
				storeVec.normalize();
			}
		}
		
		private function updatePose() : void
		{
			updateCentralPosition();
			updateSimpleJoint(XnSkeletonJoint.TORSO, SkeletonBone.SPINE);
			updateSimpleJoint(XnSkeletonJoint.NECK, SkeletonBone.NECK);
			updateSimpleJoint(XnSkeletonJoint.LEFT_SHOULDER, SkeletonBone.RIGHT_UPPER_ARM);
			updateSimpleJoint(XnSkeletonJoint.LEFT_ELBOW, SkeletonBone.RIGHT_LOWER_ARM);
			updateSimpleJoint(XnSkeletonJoint.RIGHT_SHOULDER, SkeletonBone.LEFT_UPPER_ARM);
			updateSimpleJoint(XnSkeletonJoint.RIGHT_ELBOW, SkeletonBone.LEFT_LOWER_ARM);
			updateSimpleJoint(XnSkeletonJoint.LEFT_HIP, SkeletonBone.RIGHT_UPPER_LEG);
			updateSimpleJoint(XnSkeletonJoint.LEFT_KNEE, SkeletonBone.RIGHT_LOWER_LEG);
			updateSimpleJoint(XnSkeletonJoint.RIGHT_HIP, SkeletonBone.LEFT_UPPER_LEG);
			updateSimpleJoint(XnSkeletonJoint.RIGHT_KNEE, SkeletonBone.LEFT_LOWER_LEG);
			
			updateMatrices();
		}
		
		private function updateCentralPosition() : void
		{
			var center : Vector3D = kinectUser.torso.position.world;
			
			var invPosSmoothing : Number = 1 - _posSmoothing;
			
			_localPoses[_rootJointMapIndex].translation.x = _localPoses[_rootJointMapIndex].translation.x + ((center.x - _trackingCenter.x) * _trackScale - _localPoses[_rootJointMapIndex].translation.x) * invPosSmoothing;
			_localPoses[_rootJointMapIndex].translation.y = _localPoses[_rootJointMapIndex].translation.y + ((center.y - _trackingCenter.y) * _trackScale - _localPoses[_rootJointMapIndex].translation.y) * invPosSmoothing;
			_localPoses[_rootJointMapIndex].translation.z = _localPoses[_rootJointMapIndex].translation.z + ((center.z - _trackingCenter.z) * _trackScale - _localPoses[_rootJointMapIndex].translation.z) * invPosSmoothing;
		}
		
		private function updateSimpleJoint(srcJoint:int, kinectSkeletonBoneName:String) : void
		{
			var mapIndex:int = _jointMapping[srcJoint];
			if (mapIndex < 0)
				return;
			
			_globalWisdom[mapIndex] = true;
			_globalPoses[mapIndex].orientation = getBoneOrientationFromKinectBone(kinectUser.getBoneByName(kinectSkeletonBoneName));
		}
		
		private function getBoneOrientationFromKinectBone(bone:SkeletonBone):Quaternion
		{
			var q:Quaternion = new Quaternion();
			if(bone)
			{
				
				var s:Matrix3D = bone.orientation.absoluteOrientationMatrix.clone();
				
				switch(bone.name)
				{
					case SkeletonBone.SPINE:
						break;
				}
				
				var m:Matrix3D = new Matrix3D(Vector.<Number>([
					s.rawData[0], s.rawData[4], s.rawData[8], 0,
					s.rawData[1], s.rawData[5], s.rawData[9], 0,
					s.rawData[2], s.rawData[6], s.rawData[10], 0,
					0, 0, 0, 1
				]));
				
				q.fromMatrix(m);
			}
			return q;
		}
		
		private function updateMatrices() : void
		{
			var mtx : Matrix3D = new Matrix3D();
			var mtx2 : Matrix3D = new Matrix3D();
			
			var globalMatrices:Vector.<Number> = SkeletonAnimationState(_skeletonAnimationState).globalMatrices;
			var globalMatrixIndex:int = 0;
			
			for (var i : int = 0; i < _skeleton.numJoints; ++i)
			{
				var joint:SkeletonJoint = _skeleton.joints[i];
				var globalPose:JointPose = _globalPoses[i];
				var localPose:JointPose = _localPoses[i];
				
				if (joint.parentIndex < 0)
				{
					globalPose.copyFrom(localPose);
				}
				else
				{
					var globalOrientation:Quaternion = globalPose.orientation.clone();
					var globalTranslation : Vector3D = globalPose.translation.clone();
					
					var localTranslation : Vector3D = localPose.translation;
					
					var parentPose:JointPose = _globalPoses[joint.parentIndex];
					var parentOrientation:Quaternion = parentPose.orientation;
					var parentTranslation:Vector3D = parentPose.translation;
					
					parentPose.orientation.rotatePoint(localTranslation, globalTranslation);
					
					globalTranslation.x += parentTranslation.x;
					globalTranslation.y += parentTranslation.y;
					globalTranslation.z += parentTranslation.z;
					
					globalOrientation.multiply(parentOrientation, localPose.orientation);
					globalOrientation.normalize();
					
					if (_globalWisdom[i]) 
					{
						//global orientation is now in default pose
						//what angle will we add?
						/*
						_bindPoses[i].copyToMatrix3D(mtx);
						mtx.append(globalOrientation.toMatrix3D(mtx2));
						globalOrientation.fromMatrix(mtx);
						*/
					}
					
					globalPose.orientation = globalOrientation;
					globalPose.translation = globalTranslation;
				}
				
				mtx.rawData = joint.inverseBindPose;
				mtx.append(globalPose.toMatrix3D(mtx2));
				
				var raw : Vector.<Number> = mtx.rawData;
				var smInv : Number = 1 - _jointSmoothing;
				
				globalMatrices[globalMatrixIndex] = globalMatrices[globalMatrixIndex] * _jointSmoothing + raw[0] * smInv;
				++globalMatrixIndex;
				globalMatrices[globalMatrixIndex] = globalMatrices[globalMatrixIndex] * _jointSmoothing + raw[4] * smInv;
				++globalMatrixIndex;
				globalMatrices[globalMatrixIndex] = globalMatrices[globalMatrixIndex] * _jointSmoothing + raw[8] * smInv;
				++globalMatrixIndex;
				globalMatrices[globalMatrixIndex] = globalMatrices[globalMatrixIndex] * _jointSmoothing + raw[12] * smInv;
				++globalMatrixIndex;
				globalMatrices[globalMatrixIndex] = globalMatrices[globalMatrixIndex] * _jointSmoothing + raw[1] * smInv;
				++globalMatrixIndex;
				globalMatrices[globalMatrixIndex] = globalMatrices[globalMatrixIndex] * _jointSmoothing + raw[5] * smInv;
				++globalMatrixIndex;
				globalMatrices[globalMatrixIndex] = globalMatrices[globalMatrixIndex] * _jointSmoothing + raw[9] * smInv;
				++globalMatrixIndex;
				globalMatrices[globalMatrixIndex] = globalMatrices[globalMatrixIndex] * _jointSmoothing + raw[13] * smInv;
				++globalMatrixIndex;
				globalMatrices[globalMatrixIndex] = globalMatrices[globalMatrixIndex] * _jointSmoothing + raw[2] * smInv;
				++globalMatrixIndex;
				globalMatrices[globalMatrixIndex] = globalMatrices[globalMatrixIndex] * _jointSmoothing + raw[6] * smInv;
				++globalMatrixIndex;
				globalMatrices[globalMatrixIndex] = globalMatrices[globalMatrixIndex] * _jointSmoothing + raw[10] * smInv;
				++globalMatrixIndex;
				globalMatrices[globalMatrixIndex] = globalMatrices[globalMatrixIndex] * _jointSmoothing + raw[14] * smInv;
				++globalMatrixIndex;
			}
			
			SkeletonAnimationState(_skeletonAnimationState).invalidateState();
			SkeletonAnimationState(_skeletonAnimationState).arcane::validateGlobalMatrices();
		}
	}
}