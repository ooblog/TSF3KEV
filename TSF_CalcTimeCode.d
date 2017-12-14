#! /usr/bin/env rdmd

//#TSF言語の内部で扱う電卓と暦と文字コードなど。

import std.stdio;
import core.stdc.stdio;
import std.string;
import std.windows.charset;
import std.conv;
import core.vararg;
import std.compiler;
import std.system;
import std.process;
import std.math;
import std.bigint;
import std.datetime;
import core.time;
import std.regex;
import std.algorithm;
import std.typecons;
import std.array;

//size_t TSF_maxint=size_t.max;  size_t TSF_minint=size_t.min;

string TSF_CTC_printlog(string TSF_textdup, ...){    //#TSFdoc:テキストをstdoutに表示。ログ追記もできる。(TSFAPI)
    string TSF_log=""; string TSF_text=TSF_textdup.stripRight('\n');
    if( _arguments.length>0 && _arguments[0]==typeid(string) ){
        TSF_log=va_arg!(string)(_argptr);
        if( TSF_log.length>0 ){
            TSF_log=TSF_log.back=='\n'?TSF_log:TSF_log~'\n';
        }
        TSF_log=join([TSF_log,TSF_text,"\n"]);
    }
    version(Windows){
      auto TSF_CTC_printf=toStringz(to!string(toMBSz(TSF_text)));
      printf("%s\n",TSF_CTC_printf);
//      auto TSF_CTC_printf=toStringz(TSF_text);
//      wait(spawnShell("chcp 65001"));  // UTF-8
//        printf("%s\n",TSF_CTC_printf);
//      wait(spawnShell("chcp 932"));  // Shift-JIS
    }
    else{
      auto TSF_CTC_printf=toStringz(TSF_text);
      printf("%s\n",TSF_CTC_printf);
   }
    return TSF_log;
}


unittest {
    std.stdio.writeln("unittest--- %s ---".format(__FILE__));
    TSF_CTC_printlog("日本語テスト");
//    TSF_CTC_debug(TSF_CTC_argvs(["TSFd_Io.d"]));
}


//#! -- Copyright (c) 2017-2018 ooblog --
//#! License: MIT　https://github.com/ooblog/TSF3KEV/blob/master/LICENSE
