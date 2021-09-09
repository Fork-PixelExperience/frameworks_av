/*
 * Copyright (C) 2021 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package android.media;

import android.content.AttributionSourceState;

import android.media.AudioAttributesEx;
import android.media.AudioAttributesInternal;
import android.media.AudioDevice;
import android.media.AudioDeviceDescription;
import android.media.AudioMix;
import android.media.AudioOffloadMode;
import android.media.AudioPatch;
import android.media.AudioPolicyDeviceState;
import android.media.AudioPolicyForcedConfig;
import android.media.AudioPolicyForceUse;
import android.media.AudioPort;
import android.media.AudioPortConfig;
import android.media.AudioPortRole;
import android.media.AudioPortType;
import android.media.AudioProductStrategy;
import android.media.AudioVolumeGroup;
import android.media.DeviceRole;
import android.media.EffectDescriptor;
import android.media.GetInputForAttrResponse;
import android.media.GetOutputForAttrResponse;
import android.media.GetSpatializerResponse;
import android.media.IAudioPolicyServiceClient;
import android.media.ICaptureStateListener;
import android.media.INativeSpatializerCallback;
import android.media.Int;
import android.media.SoundTriggerSession;
import android.media.audio.common.AudioConfig;
import android.media.audio.common.AudioConfigBase;
import android.media.audio.common.AudioFormatDescription;
import android.media.audio.common.AudioMode;
import android.media.audio.common.AudioOffloadInfo;
import android.media.audio.common.AudioSource;
import android.media.audio.common.AudioStreamType;
import android.media.audio.common.AudioUsage;
import android.media.audio.common.AudioUuid;

/**
 * IAudioPolicyService interface (see AudioPolicyInterface for method descriptions).
 *
 * {@hide}
 */
interface IAudioPolicyService {
    oneway void onNewAudioModulesAvailable();

    void setDeviceConnectionState(in AudioDevice device,
                                  in AudioPolicyDeviceState state,
                                  @utf8InCpp String deviceName,
                                  in AudioFormatDescription encodedFormat);

    AudioPolicyDeviceState getDeviceConnectionState(in AudioDevice device);

    void handleDeviceConfigChange(in AudioDevice device,
                                  @utf8InCpp String deviceName,
                                  in AudioFormatDescription encodedFormat);

    void setPhoneState(AudioMode state, int /* uid_t */ uid);

    void setForceUse(AudioPolicyForceUse usage,
                     AudioPolicyForcedConfig config);

    AudioPolicyForcedConfig getForceUse(AudioPolicyForceUse usage);

    int /* audio_io_handle_t */ getOutput(AudioStreamType stream);

    GetOutputForAttrResponse getOutputForAttr(in AudioAttributesInternal attr,
                                              int /* audio_session_t */ session,
                                              in AttributionSourceState attributionSource,
                                              in AudioConfig config,
                                              int /* Bitmask, indexed by AudioOutputFlags */ flags,
                                              int /* audio_port_handle_t */ selectedDeviceId);

    void startOutput(int /* audio_port_handle_t */ portId);

    void stopOutput(int /* audio_port_handle_t */ portId);

    void releaseOutput(int /* audio_port_handle_t */ portId);

    GetInputForAttrResponse getInputForAttr(in AudioAttributesInternal attr,
                                            int /* audio_io_handle_t */ input,
                                            int /* audio_unique_id_t */ riid,
                                            int /* audio_session_t */ session,
                                            in AttributionSourceState attributionSource,
                                            in AudioConfigBase config,
                                            int /* Bitmask, indexed by AudioInputFlags */ flags,
                                            int /* audio_port_handle_t */ selectedDeviceId);


    void startInput(int /* audio_port_handle_t */ portId);

    void stopInput(int /* audio_port_handle_t */ portId);

    void releaseInput(int /* audio_port_handle_t */ portId);

    void initStreamVolume(AudioStreamType stream,
                          int indexMin,
                          int indexMax);

    void setStreamVolumeIndex(AudioStreamType stream,
                              in AudioDeviceDescription device,
                              int index);

    int getStreamVolumeIndex(AudioStreamType stream,
                             in AudioDeviceDescription device);

    void setVolumeIndexForAttributes(in AudioAttributesInternal attr,
                                     in AudioDeviceDescription device,
                                     int index);

    int getVolumeIndexForAttributes(in AudioAttributesInternal attr,
                                    in AudioDeviceDescription device);

    int getMaxVolumeIndexForAttributes(in AudioAttributesInternal attr);

    int getMinVolumeIndexForAttributes(in AudioAttributesInternal attr);

    int /* product_strategy_t */ getStrategyForStream(AudioStreamType stream);

    AudioDeviceDescription[] getDevicesForStream(AudioStreamType stream);

    AudioDevice[] getDevicesForAttributes(in AudioAttributesEx attr);

    int /* audio_io_handle_t */ getOutputForEffect(in EffectDescriptor desc);

    void registerEffect(in EffectDescriptor desc,
                        int /* audio_io_handle_t */ io,
                        int /* product_strategy_t */ strategy,
                        int /* audio_session_t */ session,
                        int id);

    void unregisterEffect(int id);

    void setEffectEnabled(int id, boolean enabled);

    void moveEffectsToIo(in int[] ids, int /* audio_io_handle_t */ io);

    boolean isStreamActive(AudioStreamType stream, int inPastMs);

    boolean isStreamActiveRemotely(AudioStreamType stream, int inPastMs);

    boolean isSourceActive(AudioSource source);

    /**
     * On input, count represents the maximum length of the returned array.
     * On output, count is the total number of elements, which may be larger than the array size.
     * Passing '0' on input and inspecting the value on output is a common way of determining the
     * number of elements without actually retrieving them.
     */
    EffectDescriptor[] queryDefaultPreProcessing(int /* audio_session_t */ audioSession,
                                                 inout Int count);

    int /* audio_unique_id_t */ addSourceDefaultEffect(in AudioUuid type,
                                                       @utf8InCpp String opPackageName,
                                                       in AudioUuid uuid,
                                                       int priority,
                                                       AudioSource source);

    int /* audio_unique_id_t */ addStreamDefaultEffect(in AudioUuid type,
                                                       @utf8InCpp String opPackageName,
                                                       in AudioUuid uuid,
                                                       int priority,
                                                       AudioUsage usage);

    void removeSourceDefaultEffect(int /* audio_unique_id_t */ id);

    void removeStreamDefaultEffect(int /* audio_unique_id_t */ id);

    void setSupportedSystemUsages(in AudioUsage[] systemUsages);

    void setAllowedCapturePolicy(int /* uid_t */ uid,
                                 int /* Bitmask of AudioFlags */ capturePolicy);

    /**
     * Check if offload is possible for given format, stream type, sample rate,
     * bit rate, duration, video and streaming or offload property is enabled.
     */
    AudioOffloadMode getOffloadSupport(in AudioOffloadInfo info);

    /**
     * Check if direct playback is possible for given format, sample rate, channel mask and flags.
     */
    boolean isDirectOutputSupported(in AudioConfigBase config,
                                    in AudioAttributesInternal attributes);

    /**
     * List available audio ports and their attributes. Returns the generation.
     *
     * On input, count represents the maximum length of the returned array.
     * On output, count is the total number of elements, which may be larger than the array size.
     * Passing '0' on input and inspecting the value on output is a common way of determining the
     * number of elements without actually retrieving them.
     */
    int listAudioPorts(AudioPortRole role,
                       AudioPortType type,
                       inout Int count,
                       out AudioPort[] ports);

    /** Get attributes for a given audio port. */
    AudioPort getAudioPort(in AudioPort port);

    /**
     * Create an audio patch between several source and sink ports.
     * The handle argument is used when updating an existing patch.
     */
    int /* audio_patch_handle_t */ createAudioPatch(in AudioPatch patch, int handle);

    /** Release an audio patch. */
    void releaseAudioPatch(int /* audio_patch_handle_t */ handle);

    /**
     * List existing audio patches. Returns the generation.
     *
     * On input, count represents the maximum length of the returned array.
     * On output, count is the total number of elements, which may be larger than the array size.
     * Passing '0' on input and inspecting the value on output is a common way of determining the
     * number of elements without actually retrieving them.
     */
    int listAudioPatches(inout Int count, out AudioPatch[] patches);

    /** Set audio port configuration. */
    void setAudioPortConfig(in AudioPortConfig config);

    void registerClient(IAudioPolicyServiceClient client);

    void setAudioPortCallbacksEnabled(boolean enabled);

    void setAudioVolumeGroupCallbacksEnabled(boolean enabled);

    SoundTriggerSession acquireSoundTriggerSession();

    void releaseSoundTriggerSession(int /* audio_session_t */ session);

    AudioMode getPhoneState();

    void registerPolicyMixes(in AudioMix[] mixes, boolean registration);

    void setUidDeviceAffinities(int /* uid_t */ uid, in AudioDevice[] devices);

    void removeUidDeviceAffinities(int /* uid_t */ uid);

    void setUserIdDeviceAffinities(int userId, in AudioDevice[] devices);

    void removeUserIdDeviceAffinities(int userId);

    int /* audio_port_handle_t */ startAudioSource(in AudioPortConfig source,
                                                   in AudioAttributesInternal attributes);

    void stopAudioSource(int /* audio_port_handle_t */ portId);

    void setMasterMono(boolean mono);

    boolean getMasterMono();

    float getStreamVolumeDB(AudioStreamType stream, int index, in AudioDeviceDescription device);

    /**
     * Populates supported surround formats and their enabled state in formats and formatsEnabled.
     *
     * On input, count represents the maximum length of the returned array.
     * On output, count is the total number of elements, which may be larger than the array size.
     * Passing '0' on input and inspecting the value on output is a common way of determining the
     * number of elements without actually retrieving them.
     */
    void getSurroundFormats(inout Int count,
                            out AudioFormatDescription[] formats,
                            out boolean[] formatsEnabled);

    /**
     * Populates the surround formats reported by the HDMI devices in formats.
     *
     * On input, count represents the maximum length of the returned array.
     * On output, count is the total number of elements, which may be larger than the array size.
     * Passing '0' on input and inspecting the value on output is a common way of determining the
     * number of elements without actually retrieving them.
     */
    void getReportedSurroundFormats(inout Int count,
                                    out AudioFormatDescription[] formats);

    AudioFormatDescription[] getHwOffloadEncodingFormatsSupportedForA2DP();

    void setSurroundFormatEnabled(in AudioFormatDescription audioFormat, boolean enabled);

    void setAssistantUid(int /* uid_t */ uid);

    void setHotwordDetectionServiceUid(int /* uid_t */ uid);

    void setA11yServicesUids(in int[] /* uid_t[] */ uids);

    void setCurrentImeUid(int /* uid_t */ uid);

    boolean isHapticPlaybackSupported();

    AudioProductStrategy[] listAudioProductStrategies();
    int /* product_strategy_t */ getProductStrategyFromAudioAttributes(in AudioAttributesEx aa,
                                                                       boolean fallbackOnDefault);

    AudioVolumeGroup[] listAudioVolumeGroups();
    int /* volume_group_t */ getVolumeGroupFromAudioAttributes(in AudioAttributesEx aa,
                                                               boolean fallbackOnDefault);

    void setRttEnabled(boolean enabled);

    boolean isCallScreenModeSupported();

    void setDevicesRoleForStrategy(int /* product_strategy_t */ strategy,
                                   DeviceRole role,
                                   in AudioDevice[] devices);

    void removeDevicesRoleForStrategy(int /* product_strategy_t */ strategy,
                                       DeviceRole role);

    AudioDevice[] getDevicesForRoleAndStrategy(int /* product_strategy_t */ strategy,
                                               DeviceRole role);

    void setDevicesRoleForCapturePreset(AudioSource audioSource,
                                        DeviceRole role,
                                        in AudioDevice[] devices);

    void addDevicesRoleForCapturePreset(AudioSource audioSource,
                                        DeviceRole role,
                                        in AudioDevice[] devices);

    void removeDevicesRoleForCapturePreset(AudioSource audioSource,
                                           DeviceRole role,
                                           in AudioDevice[] devices);

    void clearDevicesRoleForCapturePreset(AudioSource audioSource,
                                          DeviceRole role);

    AudioDevice[] getDevicesForRoleAndCapturePreset(AudioSource audioSource,
                                                    DeviceRole role);

    boolean registerSoundTriggerCaptureStateListener(ICaptureStateListener listener);

    /** If a spatializer stage effect is present on the platform, this will return an
     * ISpatializer interface (see GetSpatializerResponse,aidl) to control this
     * feature.
     * If no spatializer stage is present, a null interface is returned.
     * The INativeSpatializerCallback passed must not be null.
     * Only one ISpatializer interface can exist at a given time. The native audio policy
     * service will reject the request if an interface was already acquired and previous owner
     * did not die or call ISpatializer.release().
     */
    GetSpatializerResponse getSpatializer(INativeSpatializerCallback callback);

    /** Queries if some kind of spatialization will be performed if the audio playback context
     * described by the provided arguments is present.
     * The context is made of:
     * - The audio attributes describing the playback use case.
     * - The audio configuration describing the audio format, channels, sampling rate...
     * - The devices describing the sink audio device selected for playback.
     * All arguments are optional and only the specified arguments are used to match against
     * supported criteria. For instance, supplying no argument will tell if spatialization is
     * supported or not in general.
     */
    boolean canBeSpatialized(in @nullable AudioAttributesInternal attr,
                             in @nullable AudioConfig config,
                             in AudioDevice[] devices);
}