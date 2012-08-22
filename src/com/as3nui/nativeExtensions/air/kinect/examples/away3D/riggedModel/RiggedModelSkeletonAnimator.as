package com.as3nui.nativeExtensions.air.kinect.examples.away3D.riggedModel {
import away3d.animators.AnimatorBase;
import away3d.animators.IAnimator;
import away3d.animators.SkeletonAnimationSet;
import away3d.animators.data.*;
import away3d.animators.states.*;
import away3d.animators.transitions.*;
import away3d.arcane;
import away3d.core.base.*;
import away3d.core.managers.*;
import away3d.core.math.*;
import away3d.events.*;
import away3d.materials.passes.*;

import flash.display3D.*;
import flash.geom.*;
import flash.utils.*;

use namespace arcane;

/**
 * Provides and interface for assigning skeleton-based animation data sets to mesh-based entity objects
 * and controlling the various available states of animation through an interative playhead that can be
 * automatically updated or manually triggered
 */
public class RiggedModelSkeletonAnimator extends AnimatorBase implements IAnimator {
    private var _globalMatrices:Vector.<Number>;
    private var _globalPose:SkeletonPose = new SkeletonPose();
    private var _globalPropertiesDirty:Boolean;
    private var _numJoints:uint;
    private var _bufferFormat:String;
    private var _animationStates:Dictionary = new Dictionary();
    private var _condensedMatrices:Vector.<Number>;

    private var _skeleton:Skeleton;
    private var _forceCPU:Boolean;
    private var _useCondensedIndices:Boolean;
    private var _jointsPerVertex:uint;
    private var _activeSkeletonState:ISkeletonAnimationState;

    //added
    private var _jointSmoothing:Number = .1;

    /**
     * returns the calculated global matrices of the current skeleton pose.
     *
     * @see #globalPose
     */
    public function get globalMatrices():Vector.<Number> {
        if (_globalPropertiesDirty)
            updateGlobalProperties();

        return _globalMatrices;
    }

    /**
     * returns the current skeleton pose output from the animator.
     *
     * @see away3d.animators.data.SkeletonPose
     */
    public function get globalPose():SkeletonPose {
        if (_globalPropertiesDirty)
            updateGlobalProperties();

        return _globalPose;
    }

    /**
     * Returns the skeleton object in use by the animator - this defines the number and heirarchy of joints used by the
     * skinned geoemtry to which skeleon animator is applied.
     */
    public function get skeleton():Skeleton {
        return _skeleton;
    }

    /**
     * Indicates whether the skeleton animator is disabled by default for GPU rendering, something that allows the animator to perform calculation on the GPU.
     * Defaults to false.
     */
    public function get forceCPU():Boolean {
        return _forceCPU;
    }

    /**
     * Offers the option of enabling GPU accelerated animation on skeletons larger than 32 joints
     * by condensing the number of joint index values required per mesh. Only applicable to
     * skeleton animations that utilise more than one mesh object. Defaults to false.
     */
    public function get useCondensedIndices():Boolean {
        return _useCondensedIndices;
    }

    public function set useCondensedIndices(value:Boolean):void {
        _useCondensedIndices = value;
    }

    /**
     * Creates a new <code>SkeletonAnimator</code> object.
     *
     * @param skeletonAnimationSet The animation data set containing the skeleton animation states used by the animator.
     * @param skeleton The skeleton object used for calculating the resulting global matrices for transforming skinned mesh data.
     * @param forceCPU Optional value that only allows the animator to perform calculation on the CPU. Defaults to false.
     */
    public function RiggedModelSkeletonAnimator(animationSet:SkeletonAnimationSet, skeleton:Skeleton, forceCPU:Boolean = false) {
        super(animationSet);

        _skeleton = skeleton;
        _forceCPU = forceCPU;
        _jointsPerVertex = animationSet.jointsPerVertex;

        _numJoints = _skeleton.numJoints;
        _globalMatrices = new Vector.<Number>(_numJoints * 12, true);
        _bufferFormat = "float" + _jointsPerVertex;

        var j:int;
        for (var i:uint = 0; i < _numJoints; ++i) {
            _globalMatrices[j++] = 1;
            _globalMatrices[j++] = 0;
            _globalMatrices[j++] = 0;
            _globalMatrices[j++] = 0;
            _globalMatrices[j++] = 0;
            _globalMatrices[j++] = 1;
            _globalMatrices[j++] = 0;
            _globalMatrices[j++] = 0;
            _globalMatrices[j++] = 0;
            _globalMatrices[j++] = 0;
            _globalMatrices[j++] = 1;
            _globalMatrices[j++] = 0;
        }
    }

    /**
     * Plays an animation state registered with the given name in the animation data set.
     *
     * @param stateName The data set name of the animation state to be played.
     * @param stateTransition An optional transition object that determines how the animator will transition from the currently active animation state.
     */
    public function play(name:String, transition:IAnimationTransition = null, offset:Number = NaN):void {
        if (_name == name)
            return;

        _name = name;

        if (!_animationSet.hasAnimation(name))
            throw new Error("Animation root node " + name + " not found!");

        if (transition && _activeNode) {
            //setup the transition
            _activeNode = transition.getAnimationNode(this, _activeNode, _animationSet.getAnimation(name), _absoluteTime);
            _activeNode.addEventListener(AnimationStateEvent.TRANSITION_COMPLETE, onTransitionComplete);
        } else {
            _activeNode = _animationSet.getAnimation(name);
        }

        _activeState = getAnimationState(_activeNode);

        if (updatePosition) {
            //update straight away to reset position deltas
            _activeState.update(_absoluteTime);
            _activeState.positionDelta;
        }

        _activeSkeletonState = _activeState as ISkeletonAnimationState;

        start();

        //apply a time offset if specified
        if (!isNaN(offset))
            reset(name, offset);
    }

    /**
     * @inheritDoc
     */
    public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, vertexConstantOffset:int, vertexStreamOffset:int):void {
        // do on request of globalProperties
        if (_globalPropertiesDirty)
            updateGlobalProperties();

        var skinnedGeom:SkinnedSubGeometry = SkinnedSubGeometry(SubMesh(renderable).subGeometry);

        // using condensed data
        var numCondensedJoints:uint = skinnedGeom.numCondensedJoints;
        if (_useCondensedIndices) {
            if (skinnedGeom.numCondensedJoints == 0)
                skinnedGeom.condenseIndexData();
            updateCondensedMatrices(skinnedGeom.condensedIndexLookUp, numCondensedJoints);
            stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset, _condensedMatrices, numCondensedJoints * 3);
        }
        else {
            if (_animationSet.usesCPU) {
                var subGeomAnimState:SubGeomAnimationState = _animationStates[skinnedGeom] ||= new SubGeomAnimationState(skinnedGeom);

                if (subGeomAnimState.dirty) {
                    morphGeometry(subGeomAnimState, skinnedGeom);
                    subGeomAnimState.dirty = false;
                }
                skinnedGeom.animatedVertexData = subGeomAnimState.animatedVertexData;
                skinnedGeom.animatedNormalData = subGeomAnimState.animatedNormalData;
                skinnedGeom.animatedTangentData = subGeomAnimState.animatedTangentData;
                return;
            }
            stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset, _globalMatrices, _numJoints * 3);
        }

        stage3DProxy.setSimpleVertexBuffer(vertexStreamOffset, skinnedGeom.getJointIndexBuffer(stage3DProxy), _bufferFormat, 0);
        stage3DProxy.setSimpleVertexBuffer(vertexStreamOffset + 1, skinnedGeom.getJointWeightsBuffer(stage3DProxy), _bufferFormat, 0);
    }

    /**
     * @inheritDoc
     */
    public function testGPUCompatibility(pass:MaterialPassBase):void {
        if (!_useCondensedIndices && (_forceCPU || _jointsPerVertex > 4 || pass.numUsedVertexConstants + _numJoints * 3 > 128)) {
            _animationSet.cancelGPUCompatibility();
        }
    }

    /**
     * Applies the calculated time delta to the active animation state node or state transition object.
     */
    override protected function updateDeltaTime(dt:Number):void {
        super.updateDeltaTime(dt);

        //invalidate pose matrices
        _globalPropertiesDirty = true;

        for (var key:Object in _animationStates)
            SubGeomAnimationState(_animationStates[key]).dirty = true;
    }

    private function updateCondensedMatrices(condensedIndexLookUp:Vector.<uint>, numJoints:uint):void {
        var i:uint = 0, j:uint = 0;
        var len:uint;
        var srcIndex:uint;

        _condensedMatrices = new Vector.<Number>();

        do {
            srcIndex = condensedIndexLookUp[i * 3] * 4;
            len = srcIndex + 12;
            // copy into condensed
            while (srcIndex < len)
                _condensedMatrices[j++] = _globalMatrices[srcIndex++];
        } while (++i < numJoints);
    }

    private function updateGlobalProperties() : void
    {
        _globalPropertiesDirty = false;

        //get global pose

        //localToGlobalPose(_activeSkeletonState.getSkeletonPose(_skeleton), _globalPose, _skeleton);
        //we are already on global space, no need to execute localToGlobal logic
        _globalPose = _activeSkeletonState.getSkeletonPose(_skeleton);

        // convert pose to matrix
        var mtxOffset : uint;
        var globalPoses : Vector.<JointPose> = _globalPose.jointPoses;
        var raw : Vector.<Number>;
        var ox : Number, oy : Number, oz : Number, ow : Number;
        var xy2 : Number, xz2 : Number, xw2 : Number;
        var yz2 : Number, yw2 : Number, zw2 : Number;
        var xx : Number, yy : Number, zz : Number, ww : Number;
        var n11 : Number, n12 : Number, n13 : Number, n14 : Number;
        var n21 : Number, n22 : Number, n23 : Number, n24 : Number;
        var n31 : Number, n32 : Number, n33 : Number, n34 : Number;
        var m11 : Number, m12 : Number, m13 : Number, m14 : Number;
        var m21 : Number, m22 : Number, m23 : Number, m24 : Number;
        var m31 : Number, m32 : Number, m33 : Number, m34 : Number;
        var joints : Vector.<SkeletonJoint> = _skeleton.joints;
        var pose : JointPose;
        var quat : Quaternion;
        var vec : Vector3D;

        for (var i : uint = 0; i < _numJoints; ++i) {
            pose = globalPoses[i];
            quat = pose.orientation;
            vec = pose.translation;
            ox = quat.x;	oy = quat.y;	oz = quat.z;	ow = quat.w;
            xy2 = 2.0 * ox * oy; 	xz2 = 2.0 * ox * oz; 	xw2 = 2.0 * ox * ow;
            yz2 = 2.0 * oy * oz; 	yw2 = 2.0 * oy * ow; 	zw2 = 2.0 * oz * ow;
            xx = ox * ox;			yy = oy * oy;			zz = oz * oz; 			ww = ow * ow;

            n11 = xx - yy - zz + ww;	n12 = xy2 - zw2;			n13 = xz2 + yw2;			n14 = vec.x;
            n21 = xy2 + zw2;			n22 = -xx + yy - zz + ww;	n23 = yz2 - xw2;			n24 = vec.y;
            n31 = xz2 - yw2;			n32 = yz2 + xw2;			n33 = -xx - yy + zz + ww;	n34 = vec.z;

            // prepend inverse bind pose
            raw = joints[i].inverseBindPose;
            m11 = raw[0];	m12 = raw[4];	m13 = raw[8];	m14 = raw[12];
            m21 = raw[1];	m22 = raw[5];   m23 = raw[9];	m24 = raw[13];
            m31 = raw[2];   m32 = raw[6];   m33 = raw[10];  m34 = raw[14];

            _globalMatrices[mtxOffset++] = n11 * m11 + n12 * m21 + n13 * m31;
            _globalMatrices[mtxOffset++] = n11 * m12 + n12 * m22 + n13 * m32;
            _globalMatrices[mtxOffset++] = n11 * m13 + n12 * m23 + n13 * m33;
            _globalMatrices[mtxOffset++] = n11 * m14 + n12 * m24 + n13 * m34 + n14;
            _globalMatrices[mtxOffset++] = n21 * m11 + n22 * m21 + n23 * m31;
            _globalMatrices[mtxOffset++] = n21 * m12 + n22 * m22 + n23 * m32;
            _globalMatrices[mtxOffset++] = n21 * m13 + n22 * m23 + n23 * m33;
            _globalMatrices[mtxOffset++] = n21 * m14 + n22 * m24 + n23 * m34 + n24;
            _globalMatrices[mtxOffset++] = n31 * m11 + n32 * m21 + n33 * m31;
            _globalMatrices[mtxOffset++] = n31 * m12 + n32 * m22 + n33 * m32;
            _globalMatrices[mtxOffset++] = n31 * m13 + n32 * m23 + n33 * m33;
            _globalMatrices[mtxOffset++] = n31 * m14 + n32 * m24 + n33 * m34 + n34;
        }
    }

    /**
     * If the animation can't be performed on GPU, transform vertices manually
     * @param subGeom The subgeometry containing the weights and joint index data per vertex.
     * @param pass The material pass for which we need to transform the vertices
     *
     * todo: we may be able to transform tangents more easily, similar to how it happens on gpu
     */
    private function morphGeometry(state:SubGeomAnimationState, subGeom:SkinnedSubGeometry):void {
        var verts:Vector.<Number> = subGeom.vertexData;
        var normals:Vector.<Number> = subGeom.vertexNormalData;
        var tangents:Vector.<Number> = subGeom.vertexTangentData;
        var targetVerts:Vector.<Number> = state.animatedVertexData;
        var targetNormals:Vector.<Number> = state.animatedNormalData;
        var targetTangents:Vector.<Number> = state.animatedTangentData;
        var jointIndices:Vector.<Number> = subGeom.jointIndexData;
        var jointWeights:Vector.<Number> = subGeom.jointWeightsData;
        var i1:uint, i2:uint = 1, i3:uint = 2;
        var j:uint, k:uint;
        var vx:Number, vy:Number, vz:Number;
        var nx:Number, ny:Number, nz:Number;
        var tx:Number, ty:Number, tz:Number;
        var len:int = verts.length;
        var weight:Number;
        var mtxOffset:uint;
        var vertX:Number, vertY:Number, vertZ:Number;
        var normX:Number, normY:Number, normZ:Number;
        var tangX:Number, tangY:Number, tangZ:Number;
        var m11:Number, m12:Number, m13:Number;
        var m21:Number, m22:Number, m23:Number;
        var m31:Number, m32:Number, m33:Number;

        while (i1 < len) {
            vertX = verts[i1];
            vertY = verts[i2];
            vertZ = verts[i3];
            vx = 0;
            vy = 0;
            vz = 0;
            normX = normals[i1];
            normY = normals[i2];
            normZ = normals[i3];
            nx = 0;
            ny = 0;
            nz = 0;
            tangX = tangents[i1];
            tangY = tangents[i2];
            tangZ = tangents[i3];
            tx = 0;
            ty = 0;
            tz = 0;

            // todo: can we use actual matrices when using cpu + using matrix.transformVectors, then adding them in loop?

            k = 0;
            while (k < _jointsPerVertex) {
                weight = jointWeights[j];
                if (weight == 0) {
                    j += _jointsPerVertex - k;
                    k = _jointsPerVertex;
                }
                else {
                    // implicit /3*12 (/3 because indices are multiplied by 3 for gpu matrix access, *12 because it's the matrix size)
                    mtxOffset = jointIndices[uint(j++)] * 4;
                    m11 = _globalMatrices[mtxOffset];
                    m12 = _globalMatrices[mtxOffset + 1];
                    m13 = _globalMatrices[mtxOffset + 2];
                    m21 = _globalMatrices[mtxOffset + 4];
                    m22 = _globalMatrices[mtxOffset + 5];
                    m23 = _globalMatrices[mtxOffset + 6];
                    m31 = _globalMatrices[mtxOffset + 8];
                    m32 = _globalMatrices[mtxOffset + 9];
                    m33 = _globalMatrices[mtxOffset + 10];
                    vx += weight * (m11 * vertX + m12 * vertY + m13 * vertZ + _globalMatrices[mtxOffset + 3]);
                    vy += weight * (m21 * vertX + m22 * vertY + m23 * vertZ + _globalMatrices[mtxOffset + 7]);
                    vz += weight * (m31 * vertX + m32 * vertY + m33 * vertZ + _globalMatrices[mtxOffset + 11]);

                    nx += weight * (m11 * normX + m12 * normY + m13 * normZ);
                    ny += weight * (m21 * normX + m22 * normY + m23 * normZ);
                    nz += weight * (m31 * normX + m32 * normY + m33 * normZ);
                    tx += weight * (m11 * tangX + m12 * tangY + m13 * tangZ);
                    ty += weight * (m21 * tangX + m22 * tangY + m23 * tangZ);
                    tz += weight * (m31 * tangX + m32 * tangY + m33 * tangZ);
                    k++;
                }
            }

            targetVerts[i1] = vx;
            targetVerts[i2] = vy;
            targetVerts[i3] = vz;
            targetNormals[i1] = nx;
            targetNormals[i2] = ny;
            targetNormals[i3] = nz;
            targetTangents[i1] = tx;
            targetTangents[i2] = ty;
            targetTangents[i3] = tz;

            i1 += 3;
            i2 += 3;
            i3 += 3;
        }
    }

    private function onTransitionComplete(event:AnimationStateEvent):void {
        if (event.type == AnimationStateEvent.TRANSITION_COMPLETE) {
            event.animationNode.removeEventListener(AnimationStateEvent.TRANSITION_COMPLETE, onTransitionComplete);
            //if this is the current active state transition, revert control to the active node
            if (_activeState == event.animationState) {
                _activeNode = _animationSet.getAnimation(_name);
                _activeState = getAnimationState(_activeNode);
                _activeSkeletonState = _activeState as ISkeletonAnimationState;
            }
        }
    }
}
}

import away3d.core.base.SubGeometry;

class SubGeomAnimationState {
    public var animatedVertexData:Vector.<Number>;
    public var animatedNormalData:Vector.<Number>;
    public var animatedTangentData:Vector.<Number>;
    public var dirty:Boolean = true;

    public function SubGeomAnimationState(subGeom:SubGeometry) {
        animatedVertexData = subGeom.vertexData.concat();
        animatedNormalData = subGeom.vertexNormalData.concat();
        animatedTangentData = subGeom.vertexTangentData.concat();
    }
}