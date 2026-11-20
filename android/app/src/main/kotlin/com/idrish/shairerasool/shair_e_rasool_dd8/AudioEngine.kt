
package com.idrish.shairerasool.shair_e_rasool_dd8

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.media.audiofx.NoiseSuppressor
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

class AudioEngine {

    companion object {
        private const val SAMPLE_RATE = 44100
        private const val BUFFER_SIZE_MS = 100
    }

    @Volatile private var running = false
    @Volatile private var delayMs = 300
    @Volatile private var feedback = 0.35f
    @Volatile private var effectLevel = 0.50f
    @Volatile private var ancEnabled = false
    @Volatile private var ancLevel = 5f

    private var audioRecord: AudioRecord? = null
    private var audioTrack: AudioTrack? = null
    private var noiseSuppressor: NoiseSuppressor? = null
    private var audioThread: Thread? = null

    private val delayBuffer = ShortArray(SAMPLE_RATE * 4)
    private var delayPosition = 0

    @Synchronized
    fun start(): Boolean {
        if (running) return true

        val minInput = AudioRecord.getMinBufferSize(
            SAMPLE_RATE,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )

        val minOutput = AudioTrack.getMinBufferSize(
            SAMPLE_RATE,
            AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )

        if (minInput <= 0 || minOutput <= 0) return false

        val bufferSize = max(
            minInput,
            SAMPLE_RATE * BUFFER_SIZE_MS / 1000 * 2
        )

        try {
            val recorder = AudioRecord(
                MediaRecorder.AudioSource.VOICE_RECOGNITION,
                SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                bufferSize
            )

            val track = AudioTrack.Builder()
                .setAudioAttributes(
                    android.media.AudioAttributes.Builder()
                        .setUsage(android.media.AudioAttributes.USAGE_MEDIA)
                        .setContentType(
                            android.media.AudioAttributes.CONTENT_TYPE_MUSIC
                        )
                        .build()
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setSampleRate(SAMPLE_RATE)
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build()
                )
                .setBufferSizeInBytes(max(minOutput, bufferSize))
                .setTransferMode(AudioTrack.MODE_STREAM)
                .build()

            if (recorder.state != AudioRecord.STATE_INITIALIZED ||
                track.state != AudioTrack.STATE_INITIALIZED
            ) {
                recorder.release()
                track.release()
                return false
            }

            audioRecord = recorder
            audioTrack = track

            delayBuffer.fill(0)
            delayPosition = 0

            if (NoiseSuppressor.isAvailable()) {
                try {
                    noiseSuppressor =
                        NoiseSuppressor.create(recorder.audioSessionId)
                    noiseSuppressor?.enabled = ancEnabled
                } catch (_: Exception) {
                    noiseSuppressor = null
                }
            }

            recorder.startRecording()
            track.play()

            running = true

            audioThread = Thread {
                processAudio(bufferSize / 2)
            }.apply {
                name = "DD8-Audio-Engine"
                priority = Thread.MAX_PRIORITY
                start()
            }

            return true

        } catch (_: Exception) {
            stop()
            return false
        }
    }

    private fun processAudio(frameCount: Int) {
        val input = ShortArray(frameCount)
        val output = ShortArray(frameCount)

        while (running) {
            try {
                val recorder = audioRecord ?: break
                val track = audioTrack ?: break

                val read = recorder.read(
                    input,
                    0,
                    input.size,
                    AudioRecord.READ_BLOCKING
                )

                if (read <= 0) continue

                val delaySamples = min(
                    SAMPLE_RATE * 3,
                    max(1, SAMPLE_RATE * delayMs / 1000)
                )

                for (i in 0 until read) {
                    var dry = input[i].toInt()

                    // Adjustable microphone noise gate
                    if (ancEnabled) {
                        val threshold =
                            (80f + ancLevel * 40f).toInt()

                        if (abs(dry) < threshold) {
                            dry = (dry * 0.45f).toInt()
                        }
                    }

                    val delayedPosition =
                        (delayPosition - delaySamples +
                            delayBuffer.size) % delayBuffer.size

                    val echo =
                        delayBuffer[delayedPosition].toInt()

                    val mixed =
                        dry * effectLevel + echo * feedback

                    output[i] = mixed.toInt().coerceIn(
                        Short.MIN_VALUE.toInt(),
                        Short.MAX_VALUE.toInt()
                    ).toShort()

                    delayBuffer[delayPosition] =
                        (dry + echo * feedback).toInt().coerceIn(
                            Short.MIN_VALUE.toInt(),
                            Short.MAX_VALUE.toInt()
                        ).toShort()

                    delayPosition =
                        (delayPosition + 1) % delayBuffer.size
                }

                track.write(
                    output,
                    0,
                    read,
                    AudioTrack.WRITE_BLOCKING
                )

            } catch (_: Exception) {
                running = false
            }
        }
    }

    fun setDelay(milliseconds: Int) {
        delayMs = milliseconds.coerceIn(50, 3200)
    }

    fun setFeedback(value: Float) {
        feedback = value.coerceIn(0f, 0.85f)
    }

    fun setEffectLevel(value: Float) {
        effectLevel = value.coerceIn(0f, 1f)
    }

    fun setAncEnabled(enabled: Boolean) {
        ancEnabled = enabled

        try {
            noiseSuppressor?.enabled = enabled
        } catch (_: Exception) {
        }
    }

    fun setAncLevel(value: Float) {
        ancLevel = value.coerceIn(0f, 10f)
    }

    @Synchronized
    fun stop() {
        running = false

        try {
            audioThread?.join(500)
        } catch (_: InterruptedException) {
            Thread.currentThread().interrupt()
        }

        audioThread = null

        try {
            audioRecord?.stop()
        } catch (_: Exception) {
        }

        try {
            audioTrack?.pause()
            audioTrack?.flush()
            audioTrack?.stop()
        } catch (_: Exception) {
        }

        try {
            noiseSuppressor?.release()
        } catch (_: Exception) {
        }

        noiseSuppressor = null

        audioRecord?.release()
        audioTrack?.release()

        audioRecord = null
        audioTrack = null
    }
}
