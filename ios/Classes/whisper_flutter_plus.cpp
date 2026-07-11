#include "whisper/whisper.h"

#define DR_WAV_IMPLEMENTATION
#include "whisper/examples/dr_wav.h"

#include <cmath>
#include <fstream>
#include <cstdio>
#include <string>
#include <thread>
#include <mutex>
#include <algorithm>
#include <cstdlib>
#include <vector>

#include <iostream>
#include "json/json.hpp"
#include <stdio.h>

using json = nlohmann::json;

void print(std::string value)
{
    std::cout << value << std::endl;
}

char *jsonToChar(json jsonData)
{
    // Whisper can emit text that splits a multi-byte UTF-8 character at a
    // token boundary; dump() would throw type_error.316 and abort the app
    // across the FFI boundary. Replace invalid bytes with U+FFFD instead.
    std::string result =
        jsonData.dump(-1, ' ', false, json::error_handler_t::replace);
    // malloc, not new[]: callers across the FFI boundary free this
    // with the C allocator (Dart's malloc.free).
    char *ch = (char *)malloc(result.size() + 1);
    strcpy(ch, result.c_str());
    return ch;
}

std::string charToString(char *value)
{
    std::string result(value);
    return result;
}

char *stringToChar(std::string value)
{
    char *ch = (char *)malloc(value.size() + 1);
    strcpy(ch, value.c_str());
    return ch;
}

// //  500 -> 00:05.000
// // 6000 -> 01:00.000
// std::string to_timestamp(int64_t t)
// {
//     int64_t sec = t / 100;
//     int64_t msec = t - sec * 100;
//     int64_t min = sec / 60;
//     sec = sec - min * 60;

//     char buf[32];
//     snprintf(buf, sizeof(buf), "%02d:%02d.%03d", (int)min, (int)sec, (int)msec);

//     return std::string(buf);
// }

// Terminal color map. 10 colors grouped in ranges [0.0, 0.1, ..., 0.9]
// Lowest is red, middle is yellow, highest is green.
const std::vector<std::string> k_colors = {
    "\033[38;5;196m",
    "\033[38;5;202m",
    "\033[38;5;208m",
    "\033[38;5;214m",
    "\033[38;5;220m",
    "\033[38;5;226m",
    "\033[38;5;190m",
    "\033[38;5;154m",
    "\033[38;5;118m",
    "\033[38;5;82m",
};

//  500 -> 00:05.000
// 6000 -> 01:00.000
std::string to_timestamp(int64_t t, bool comma = false)
{
    int64_t msec = t * 10;
    int64_t hr = msec / (1000 * 60 * 60);
    msec = msec - hr * (1000 * 60 * 60);
    int64_t min = msec / (1000 * 60);
    msec = msec - min * (1000 * 60);
    int64_t sec = msec / 1000;
    msec = msec - sec * 1000;

    char buf[32];
    snprintf(buf, sizeof(buf), "%02d:%02d:%02d%s%03d", (int)hr, (int)min, (int)sec, comma ? "," : ".", (int)msec);

    return std::string(buf);
}

int timestamp_to_sample(int64_t t, int n_samples)
{
    return std::max(0, std::min((int)n_samples - 1, (int)((t * WHISPER_SAMPLE_RATE) / 100)));
}

// command-line parameters
struct whisper_params
{
    int32_t seed = -1; // RNG seed, not used currently
    int32_t n_threads = std::min(4, (int32_t)std::thread::hardware_concurrency());

    int32_t n_processors = 1;
    int32_t offset_t_ms = 0;
    int32_t offset_n = 0;
    int32_t duration_ms = 0;
    int32_t max_context = -1;
    int32_t max_len = 0;
    int32_t best_of = 5;
    int32_t beam_size = -1;

    float word_thold = 0.01f;
    float entropy_thold = 2.40f;
    float logprob_thold = -1.00f;

    bool verbose = false;
    bool print_special_tokens = false;
    bool speed_up = false;
    bool translate = false;
    bool diarize = false;
    bool no_fallback = false;
    bool output_txt = false;
    bool output_vtt = false;
    bool output_srt = false;
    bool output_wts = false;
    bool output_csv = false;
    bool print_special = false;
    bool print_colors = false;
    bool print_progress = false;
    bool no_timestamps = false;
    bool split_on_word = false;
    // whisper_full_params.no_context: disable cross-segment text conditioning.
    bool no_context = false;
    // whisper_full_params.suppress_non_speech_tokens: drop [BLANK_AUDIO]-style annotations.
    bool suppress_nst = false;

    std::string language = "id";
    std::string prompt;
    std::string model = "models/ggml-model-whisper-small.bin";
    std::string audio = "samples/jfk.wav";
    std::vector<std::string> fname_inp = {};
    std::vector<std::string> fname_outp = {};
};

struct whisper_print_user_data
{
    const whisper_params *params;

    const std::vector<std::vector<float>> *pcmf32s;
};

json transcribe(json jsonBody)
{
    whisper_params params;

    params.n_threads = jsonBody["threads"];
    params.verbose = jsonBody["is_verbose"];
    params.translate = jsonBody["is_translate"];
    params.language = jsonBody["language"];
    params.print_special_tokens = jsonBody["is_special_tokens"];
    params.no_timestamps = jsonBody["is_no_timestamps"];
    params.model = jsonBody["model"];
    params.audio = jsonBody["audio"];
    params.split_on_word = jsonBody["split_on_word"];
    params.diarize = jsonBody["diarize"];

    // Optional fields: absent / null / empty leaves whisper.cpp defaults.
    if (jsonBody.contains("initial_prompt") && jsonBody["initial_prompt"].is_string())
    {
        params.prompt = jsonBody["initial_prompt"].get<std::string>();
    }
    if (jsonBody.contains("no_context") && jsonBody["no_context"].is_boolean())
    {
        params.no_context = jsonBody["no_context"].get<bool>();
    }
    if (jsonBody.contains("suppress_non_speech_tokens") && jsonBody["suppress_non_speech_tokens"].is_boolean())
    {
        params.suppress_nst = jsonBody["suppress_non_speech_tokens"].get<bool>();
    }
    json jsonResult;
    jsonResult["@type"] = "transcribe";

    if (whisper_lang_id(params.language.c_str()) == -1)
    {
        jsonResult["@type"] = "error";
        jsonResult["message"] = "error: unknown language";
        return jsonResult;
    }

    if (params.seed < 0)
    {
        params.seed = time(NULL);
    }

    // whisper init
    struct whisper_context *ctx = whisper_init_from_file(params.model.c_str());

    // struct whisper_context *ctx = whisper_init(params.model.c_str());
    std::string text_result = "";
    // for (int f = 0; f < (int)params.fname_inp.size(); ++f)
    // {
    const auto fname_inp = params.audio;
    // WAV input
    std::vector<float> pcmf32;
    {
        drwav wav;
        if (!drwav_init_file(&wav, fname_inp.c_str(), NULL))
        {
            jsonResult["@type"] = "error";
            jsonResult["message"] = " failed to open WAV file ";
            return jsonResult;
        }

        if (wav.channels != 1 && wav.channels != 2)
        {
            jsonResult["@type"] = "error";
            jsonResult["message"] = "must be mono or stereo";
            return jsonResult;
        }

        if (wav.sampleRate != WHISPER_SAMPLE_RATE)
        {
            jsonResult["@type"] = "error";
            jsonResult["message"] = "WAV file  must be 16 kHz";
            return jsonResult;
        }

        if (wav.bitsPerSample != 16)
        {
            jsonResult["@type"] = "error";
            jsonResult["message"] = "WAV file  must be 16 bit";
            return jsonResult;
        }

        int n = wav.totalPCMFrameCount;

        std::vector<int16_t> pcm16;
        pcm16.resize(n * wav.channels);
        drwav_read_pcm_frames_s16(&wav, n, pcm16.data());
        drwav_uninit(&wav);

        // convert to mono, float
        pcmf32.resize(n);
        if (wav.channels == 1)
        {
            for (int i = 0; i < n; i++)
            {
                pcmf32[i] = float(pcm16[i]) / 32768.0f;
            }
        }
        else
        {
            for (int i = 0; i < n; i++)
            {
                pcmf32[i] = float(pcm16[2 * i] + pcm16[2 * i + 1]) / 65536.0f;
            }
        }
    }

    // print some info about the processing
    {
        // printf("\n");
        if (!whisper_is_multilingual(ctx))
        {
            if (params.language != "en" || params.translate)
            {
                params.language = "en";
                params.translate = false;
                // printf("%s: WARNING: model is not multilingual, ignoring language and translation options\n", __func__);
            }
        }
        // printf("%s: processing '%s' (%d samples, %.1f sec), %d threads, lang = %s, task = %s, timestamps = %d ...\n",
        //        __func__, fname_inp.c_str(), int(pcmf32.size()), float(pcmf32.size()) / WHISPER_SAMPLE_RATE, params.n_threads,
        //        params.language.c_str(),
        //        params.translate ? "translate" : "transcribe",
        //        params.no_timestamps ? 0 : 1);
        // printf("\n");
    }
    // run the inference
    {
        whisper_full_params wparams = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);

        wparams.print_realtime = false;
        wparams.print_progress = false;
        wparams.print_timestamps = !params.no_timestamps;
        // wparams.print_special_tokens = params.print_special_tokens;
        wparams.translate = params.translate;
        wparams.language = params.language.c_str();
        wparams.n_threads = params.n_threads;
        wparams.split_on_word = params.split_on_word;

        // params.prompt outlives whisper_full(), so the pointer stays valid.
        if (!params.prompt.empty()) {
            wparams.initial_prompt = params.prompt.c_str();
        }
        wparams.no_context = params.no_context;
        wparams.suppress_non_speech_tokens = params.suppress_nst;

        if (params.split_on_word) {
            wparams.max_len = 1;
            wparams.token_timestamps = true;
        }

        if (whisper_full(ctx, wparams, pcmf32.data(), pcmf32.size()) != 0)
        {
            jsonResult["@type"] = "error";
            jsonResult["message"] = "failed to process audio";
            return jsonResult;
        }

        

        // print result;
        if (!wparams.print_realtime)
        {

            const int n_segments = whisper_full_n_segments(ctx);

            std::vector<json> segmentsJson = {};

            for (int i = 0; i < n_segments; ++i)
            {
                const char *text = whisper_full_get_segment_text(ctx, i);

                std::string str(text);
                text_result += str;
                if (params.no_timestamps)
                {
                    // printf("%s", text);
                    // fflush(stdout);
                } else {
                    json jsonSegment;
                    const int64_t t0 = whisper_full_get_segment_t0(ctx, i);
                    const int64_t t1 = whisper_full_get_segment_t1(ctx, i);

                    // printf("[%s --> %s]  %s\n", to_timestamp(t0).c_str(), to_timestamp(t1).c_str(), text);

                    jsonSegment["from_ts"] = t0;
                    jsonSegment["to_ts"] = t1;
                    jsonSegment["text"] = text;

                    segmentsJson.push_back(jsonSegment);
                }
            }

            if (!params.no_timestamps) {
                jsonResult["segments"] = segmentsJson;
            }
        }
    }
    jsonResult["text"] = text_result;
    
    whisper_free(ctx);
    return jsonResult;
}

extern "C"
{
    char *request(char *body)
    {
        json jsonBody = json::parse(body);
        json jsonResult;

        if (jsonBody["@type"] == "getTextFromWavFile")
        {
            return jsonToChar(transcribe(jsonBody));
        }

        if (jsonBody["@type"] == "getVersion")
        {
            jsonResult["@type"] = "version";
            jsonResult["message"] = "version lib v0.0.0";
            return jsonToChar(jsonResult);
        }

        jsonResult["@type"] = "error";
        jsonResult["message"] = "method not found";
        return jsonToChar(jsonResult);
    }

    int main()
    {
        json jsonBody;
        jsonBody["@type"] = "al";
        print(transcribe(jsonBody).dump());
        return 0;
    }
}

// ---------------------------------------------------------------------------
// Live (streaming) transcription.
//
// Unlike request()/transcribe(), which load the model on every call, a stream
// keeps one whisper_context alive for the whole session:
//
//   stream_start(json)          -> loads the model, resets state
//   stream_feed(pcm, n)         -> appends 16 kHz mono float samples; re-runs
//                                  inference when >= ~1.5 s of new audio has
//                                  accumulated and returns the partial text
//   stream_stop()               -> final text, frees the context
//
// Partials re-decode the whole current window with no_context = true, so a
// wrong early partial does not condition later ones. When the window grows
// past ~25 s its text is committed and the buffer restarts, keeping memory
// and inference time bounded (a word straddling the commit boundary may be
// clipped — acceptable for a draft).
//
// An RMS energy gate tracks the last voiced sample: inference only runs
// when new voiced audio has arrived, and the decoded window is trimmed
// shortly after the last voiced sample. Without this, whisper hallucinates
// over trailing silence (repeating earlier text or inventing phrases).
// ---------------------------------------------------------------------------

struct whisper_stream_state
{
    struct whisper_context *ctx = nullptr;
    std::vector<float> pcmf32;   // samples of the current window
    size_t n_transcribed = 0;    // window samples covered by the last run
    size_t n_voiced = 0;         // end of the last chunk with speech energy
    float noise_floor = 0.005f;  // adaptive ambient RMS estimate
    float gate_rms_min = 0.0015f;   // absolute minimum speech RMS
    float gate_ratio = 2.5f;        // voiced thold = ratio * noise_floor
    float gate_floor_cap = 0.01f;   // noise_floor cap (loud rooms)
    std::string committed;       // text of windows already committed
    std::string last_text;       // text of the current window's last run
    std::string language = "en";
    std::string prompt;
    int n_threads = 4;
    bool translate = false;
    bool suppress_nst = false;
    std::mutex mutex;
};

static whisper_stream_state g_stream;

static const size_t STREAM_STEP_SAMPLES   = (size_t)(1.5 * WHISPER_SAMPLE_RATE);
static const size_t STREAM_COMMIT_SAMPLES = (size_t)(25.0 * WHISPER_SAMPLE_RATE);
// Decode this much audio past the last voiced sample (trailing consonants).
static const size_t STREAM_VOICE_PAD      = (size_t)(0.2 * WHISPER_SAMPLE_RATE);

// Runs whisper_full over the current window. Caller must hold g_stream.mutex.
static json stream_run_inference()
{
    json result;
    result["@type"] = "streamPartial";

    whisper_full_params wparams = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
    wparams.print_realtime   = false;
    wparams.print_progress   = false;
    wparams.print_timestamps = false;
    wparams.translate        = g_stream.translate;
    wparams.language         = g_stream.language.c_str();
    wparams.n_threads        = g_stream.n_threads;
    wparams.no_context       = true;
    wparams.suppress_non_speech_tokens = g_stream.suppress_nst;
    if (!g_stream.prompt.empty()) {
        wparams.initial_prompt = g_stream.prompt.c_str();
    }

    // Trim trailing silence from the decode window; decoding it makes
    // whisper hallucinate (repeats or invented phrases).
    const size_t n_decode =
        std::min(g_stream.pcmf32.size(), g_stream.n_voiced + STREAM_VOICE_PAD);
    if (n_decode < (size_t)WHISPER_SAMPLE_RATE / 2) {
        result["text"] = g_stream.committed + g_stream.last_text;
        return result;
    }

    if (whisper_full(g_stream.ctx, wparams, g_stream.pcmf32.data(),
                     (int)n_decode) != 0) {
        result["@type"] = "error";
        result["message"] = "failed to process audio";
        return result;
    }

    std::string text;
    const int n_segments = whisper_full_n_segments(g_stream.ctx);
    for (int i = 0; i < n_segments; ++i) {
        text += whisper_full_get_segment_text(g_stream.ctx, i);
    }

    g_stream.last_text = text;
    g_stream.n_transcribed = n_decode;

    if (n_decode >= STREAM_COMMIT_SAMPLES) {
        g_stream.committed += text;
        g_stream.last_text.clear();
        g_stream.pcmf32.erase(g_stream.pcmf32.begin(),
                              g_stream.pcmf32.begin() + n_decode);
        g_stream.n_transcribed = 0;
        g_stream.n_voiced -= std::min(g_stream.n_voiced, n_decode);
    }

    result["text"] = g_stream.committed + g_stream.last_text;
    return result;
}

extern "C"
{
    // body: {"model": path, "language": "en", "threads": 4,
    //        "is_translate": false, "initial_prompt": "..."}
    char *stream_start(char *body)
    {
        std::lock_guard<std::mutex> lock(g_stream.mutex);
        json jsonResult;

        json jsonBody = json::parse(body, nullptr, false);
        if (jsonBody.is_discarded() || !jsonBody.contains("model")) {
            jsonResult["@type"] = "error";
            jsonResult["message"] = "stream_start: invalid request body";
            return jsonToChar(jsonResult);
        }

        if (g_stream.ctx != nullptr) {
            whisper_free(g_stream.ctx);
            g_stream.ctx = nullptr;
        }
        g_stream.pcmf32.clear();
        g_stream.n_transcribed = 0;
        g_stream.n_voiced = 0;
        g_stream.noise_floor = 0.005f;
        g_stream.committed.clear();
        g_stream.last_text.clear();

        std::string model;
        try {
            g_stream.language  = jsonBody.value("language", "en");
            g_stream.n_threads = jsonBody.value("threads", 4);
            g_stream.translate = jsonBody.value("is_translate", false);
            g_stream.suppress_nst = jsonBody.value("suppress_non_speech_tokens", false);
            g_stream.gate_rms_min   = (float)jsonBody.value("gate_rms_min", 0.0015);
            g_stream.gate_ratio     = (float)jsonBody.value("gate_voice_ratio", 2.5);
            g_stream.gate_floor_cap = (float)jsonBody.value("gate_floor_cap", 0.01);
            g_stream.prompt.clear();
            if (jsonBody.contains("initial_prompt") && jsonBody["initial_prompt"].is_string()) {
                g_stream.prompt = jsonBody["initial_prompt"].get<std::string>();
            }
            model = jsonBody["model"].get<std::string>();
        } catch (const json::exception &e) {
            // A C++ exception escaping extern "C" into FFI would be
            // std::terminate; convert type errors to an error response.
            jsonResult["@type"] = "error";
            jsonResult["message"] =
                std::string("stream_start: bad request: ") + e.what();
            return jsonToChar(jsonResult);
        }
        g_stream.ctx = whisper_init_from_file(model.c_str());
        if (g_stream.ctx == nullptr) {
            jsonResult["@type"] = "error";
            jsonResult["message"] = "stream_start: failed to load model " + model;
            return jsonToChar(jsonResult);
        }

        jsonResult["@type"] = "streamStarted";
        return jsonToChar(jsonResult);
    }

    // pcm: 16 kHz mono float32 samples in [-1, 1].
    char *stream_feed(const float *pcm, int32_t n_samples)
    {
        std::lock_guard<std::mutex> lock(g_stream.mutex);
        json jsonResult;

        if (g_stream.ctx == nullptr) {
            jsonResult["@type"] = "error";
            jsonResult["message"] = "stream_feed: stream not started";
            return jsonToChar(jsonResult);
        }
        if (pcm != nullptr && n_samples > 0) {
            double sum2 = 0.0;
            for (int32_t i = 0; i < n_samples; ++i) {
                sum2 += (double)pcm[i] * pcm[i];
            }
            g_stream.pcmf32.insert(g_stream.pcmf32.end(), pcm, pcm + n_samples);

            // Adaptive noise floor: falls quickly, rises slowly, so it
            // tracks room tone without absorbing speech. A chunk is
            // voiced only when clearly above the floor.
            const float rms = (float)std::sqrt(sum2 / n_samples);
            if (rms < g_stream.noise_floor) {
                g_stream.noise_floor += 0.5f * (rms - g_stream.noise_floor);
            } else {
                g_stream.noise_floor += 0.0005f * (rms - g_stream.noise_floor);
            }
            g_stream.noise_floor =
                std::min(g_stream.noise_floor, g_stream.gate_floor_cap);
            const float voice_thold = std::max(
                g_stream.gate_ratio * g_stream.noise_floor,
                g_stream.gate_rms_min);
            if (rms >= voice_thold) {
                g_stream.n_voiced = g_stream.pcmf32.size();
            }
        }

        // Run only when new *voiced* audio arrived — silence alone
        // never triggers a decode.
        if (g_stream.n_voiced > g_stream.n_transcribed &&
            g_stream.pcmf32.size() - g_stream.n_transcribed >= STREAM_STEP_SAMPLES) {
            return jsonToChar(stream_run_inference());
        }

        jsonResult["@type"] = "streamPartial";
        jsonResult["text"] = g_stream.committed + g_stream.last_text;
        return jsonToChar(jsonResult);
    }

    char *stream_stop()
    {
        std::lock_guard<std::mutex> lock(g_stream.mutex);
        json jsonResult;

        if (g_stream.ctx == nullptr) {
            jsonResult["@type"] = "error";
            jsonResult["message"] = "stream_stop: stream not started";
            return jsonToChar(jsonResult);
        }

        // Cover voiced audio that arrived after the last run; a silent
        // tail is dropped rather than decoded.
        const size_t n_tail = std::min(g_stream.pcmf32.size(),
                                       g_stream.n_voiced + STREAM_VOICE_PAD);
        if (g_stream.n_voiced > g_stream.n_transcribed &&
            n_tail >= (size_t)WHISPER_SAMPLE_RATE / 2) {
            stream_run_inference();
        }

        jsonResult["@type"] = "streamFinal";
        jsonResult["text"] = g_stream.committed + g_stream.last_text;

        whisper_free(g_stream.ctx);
        g_stream.ctx = nullptr;
        g_stream.pcmf32.clear();
        g_stream.pcmf32.shrink_to_fit();
        g_stream.n_transcribed = 0;
        g_stream.n_voiced = 0;
        g_stream.committed.clear();
        g_stream.last_text.clear();

        return jsonToChar(jsonResult);
    }
}
