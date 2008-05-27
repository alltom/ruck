/* This builds for me (with make) into an audio.bundle which Ruby seems
   to recognize, but when I try to load it with require("audio"), I get
   this cryptic (to me) error message:
   
   LoadError: dlopen(./audio.bundle, 9): Symbol not found: __ZTISt9exception
      Referenced from: /Users/tom/Projects/Mine/ruck/ruby/audio/audio.bundle
      Expected in: dynamic lookup
     - ./audio.bundle
        	from ./audio.bundle
        	from (irb):1
        	from :0
   
   ... does anyone know how to make this work? */

#include "ruby.h"
#include "vector"
#include "iostream"
#include "map"
#include "RtAudio.h"

typedef VALUE (ruby_method)(...);

int tick( void *outputBuffer, void *inputBuffer, unsigned int inBufferFrames,
         double streamTime, RtAudioStreamStatus status, void *dataPointer )
{
  return 0;
}

class Dac
{
public:

  RtAudio *dac;
  RtAudio::DeviceInfo info;
  RtAudio::StreamParameters parameters;

  void hello(){ std::cout << "hello" << std::endl; }

  void probe(){
    // Create an api map.
    std::map<int, std::string> apiMap;
    apiMap[RtAudio::MACOSX_CORE] = "OS-X Core Audio";
    apiMap[RtAudio::WINDOWS_ASIO] = "Windows ASIO";
    apiMap[RtAudio::WINDOWS_DS] = "Windows Direct Sound";
    apiMap[RtAudio::UNIX_JACK] = "Jack Client";
    apiMap[RtAudio::LINUX_ALSA] = "Linux ALSA";
    apiMap[RtAudio::LINUX_OSS] = "Linux OSS";
    apiMap[RtAudio::RTAUDIO_DUMMY] = "RtAudio Dummy";

    std::vector<RtAudio::Api> apis;
    RtAudio::getCompiledApi( apis );

    std::cout << "\nCompiled APIs:\n";
    for (unsigned int i=0; i < apis.size(); i++ )
      std::cout << "  " << apiMap[ apis[i] ] << std::endl;

    std::cout << "\nCurrent API: " << apiMap[ dac->getCurrentApi() ] << std::endl;

    unsigned int devices = dac->getDeviceCount();
    std::cout << "\nFound " << devices << " device(s) ...\n";

    for (unsigned int i=0; i < devices; i++) {
       info = dac->getDeviceInfo(i);
       std::cout << "\nDevice Name = " << info.name;
     }
  }


  void start()
  {  
    RtAudioFormat format = RTAUDIO_FLOAT32;
    unsigned int bufferFrames = 0, sampleRate = 44100;
    try {
      dac->openStream( &parameters, NULL, format, sampleRate, &bufferFrames, &tick, NULL );
      dac->startStream();
    }
    catch ( RtError &error ) {
      error.printMessage();
    }
  }

  void stop()
  {  
    try {
      dac->closeStream();
    }
    catch ( RtError &error ) {
      error.printMessage();
    }
  }

  Dac() { 
    dac = new RtAudio();
    // some info and setup of the dac
    int device_id = dac->getDefaultOutputDevice();
    int num_channels = dac->getDeviceInfo(device_id).outputChannels;
    parameters.deviceId = device_id;
    parameters.nChannels = 1;
    std::cout << "Default output device id: " << device_id << std::endl;
    std::cout << "Output channels: " << num_channels << std::endl;
  }

  ~Dac() { 
    std::cout << "unmaking Audio" << std::endl; 
    delete dac;
  }
};

/////////////////////////////////////////////////
extern "C" 
{

  static void audio_free(Dac *simple) {
    delete simple;
  }

  // alloc
  static VALUE audio_alloc(VALUE klass) {
    Dac *audio = new Dac;
    return Data_Wrap_Struct(klass, 0, audio_free, audio);
  }

  // initialize
  static VALUE audio_initialize(VALUE self) {
    Dac *audio = NULL;
    Data_Get_Struct(self, Dac, audio);
    return self;
  }

  static VALUE audio_hello(VALUE self){
    Dac *audio = NULL;
    Data_Get_Struct(self, Dac, audio);
    audio->hello();
    return Qnil;
  }

  static VALUE audio_probe(VALUE self){
    Dac *audio = NULL;
    Data_Get_Struct(self, Dac, audio);
    audio->probe();
    return Qnil;
  }

  static VALUE audio_start(VALUE self){
    Dac *audio = NULL;
    Data_Get_Struct(self, Dac, audio);
    audio->start();
    return Qnil;
  }

  static VALUE audio_stop(VALUE self){
    Dac *audio = NULL;
    Data_Get_Struct(self, Dac, audio);
    audio->stop();
    return Qnil;
  }


  ////////////////////////////////////////////////////////////

  VALUE cAudio;

  void Init_audio() 
  {
    cAudio = rb_define_class("Audio", rb_cObject);
    rb_define_alloc_func(cAudio, audio_alloc);
    rb_define_method(cAudio, "initialize", (ruby_method*) &audio_initialize, 0);
    rb_define_method(cAudio, "hello", (ruby_method*) &audio_hello, 0);
    rb_define_method(cAudio, "probe", (ruby_method*) &audio_probe, 0);
    rb_define_method(cAudio, "start", (ruby_method*) &audio_start, 0);
    rb_define_method(cAudio, "stop", (ruby_method*) &audio_stop, 0);
    // rb_define_method(cAudio, "stop", (ruby_method*) &audio_stop, 0);
    //id_push = rb_intern("push");
  }

} // extern "C"
