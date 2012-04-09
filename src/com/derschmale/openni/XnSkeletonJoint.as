package com.derschmale.openni
{
	import com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint;
	

	public class XnSkeletonJoint
	{
		public static const HEAD : int = 0;
		public static const NECK : int = 1;
		public static const TORSO : int = 2;

		public static const LEFT_SHOULDER : int = 3;
		public static const LEFT_ELBOW : int = 4;
		public static const LEFT_HAND : int = 5;

		public static const RIGHT_SHOULDER : int = 6;
		public static const RIGHT_ELBOW : int = 7;
		public static const RIGHT_HAND : int = 8;

		public static const LEFT_HIP : int = 9;
		public static const LEFT_KNEE : int = 10;
		public static const LEFT_FOOT : int = 11;

		public static const RIGHT_HIP : int = 12;
		public static const RIGHT_KNEE : int = 13;
		public static const RIGHT_FOOT : int = 14;
		
		public static const NAMES_BY_INDEX:Vector.<String> = Vector.<String>([
			SkeletonJoint.HEAD,
			SkeletonJoint.NECK,
			SkeletonJoint.TORSO,
			SkeletonJoint.LEFT_SHOULDER,
			SkeletonJoint.LEFT_ELBOW,
			SkeletonJoint.LEFT_HAND,
			SkeletonJoint.RIGHT_SHOULDER,
			SkeletonJoint.RIGHT_ELBOW,
			SkeletonJoint.RIGHT_HAND,
			SkeletonJoint.LEFT_HIP,
			SkeletonJoint.LEFT_KNEE,
			SkeletonJoint.LEFT_FOOT,
			SkeletonJoint.RIGHT_HIP,
			SkeletonJoint.RIGHT_KNEE,
			SkeletonJoint.RIGHT_FOOT
		]);

	}
}
