#! /usr/bin/env rdmd

//#TSF言語の内部で扱う電卓と暦と文字コードなど。

import std.stdio;
import core.stdc.stdio;
import std.string;
import std.windows.charset;
import std.file;
import std.path;
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
      if( TSF_log.length>0 ){  TSF_log=TSF_log.back=='\n'?TSF_log:TSF_log~'\n';  }
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
      std.stdio.writeln(TSF_text);
   }
    return TSF_log;
}

string TSF_CTC_loadtext(string TSF_path, ...){    //#TSFdoc:ファイルからテキストを読み込む。通常「UTF-8」を扱う。(TSFAPI)
    string TSF_text="";
    string TSF_encoding="utf-8";
    if( _arguments.length>0 && _arguments[0]==typeid(string) ){
      TSF_encoding=va_arg!(string)(_argptr); TSF_encoding=toLower(TSF_encoding);
    }
    foreach(string TSF_utf8;["utf-8","utf_8","u8","utf","utf8"]){
      if(TSF_encoding==TSF_utf8){ TSF_encoding="utf-8"; break; }
    }
    foreach(string TSF_sjis;["cp932","932","mskanji","ms-kanji","sjis","shiftjis","shift-jis","shift_jis"]){
      if(TSF_encoding==TSF_sjis){ TSF_encoding="cp932"; break; }
    }
    if( exists(TSF_path) ){
      TSF_text=readText(TSF_path);
      switch( TSF_encoding ){
        case "cp932":
//          TSF_text=fromMBSz(toStringz(to!char[](TSF_text)));
        default:  break;
      }
    }
    return TSF_text;
}

void TSF_CTC_savedir(string TSF_path){    //#TSFdoc:「TS_CTC_savetext()」でファイル保存する時、1階層分のフォルダを作成する。(TSFAPI)
    string TS_CTC_workdir=dirName(absolutePath(TSF_path));
    if( exists(TS_CTC_workdir)==false && TS_CTC_workdir.length>0 ){
      mkdir(TS_CTC_workdir);
    }
}

void TSF_CTC_savedirs(string TSF_path){    //#TSFdoc:一気に深い階層のフォルダを複数作れてしまうので取扱い注意(扱わない)。(TSFAPI)
    string TS_CTC_workdir=dirName(absolutePath(TSF_path));
    if( exists(TS_CTC_workdir)==false && TS_CTC_workdir.length>0 ){
      mkdirRecurse(TS_CTC_workdir);
    }
}

void TSF_CTC_savetext(string TSF_path, ...){    //#TSFdoc:TSF_pathにTSF_textを保存する。TSF_textを省略した場合ファイルを削除。(TSFAPI)
    string TSF_text="";  bool TSF_remove=true;
    if( _arguments.length>0 && _arguments[0]==typeid(string) ){
      TSF_text=va_arg!(string)(_argptr); TSF_remove=false;
      if( TSF_text.length>0 ){  TSF_text=TSF_text.back=='\n'?TSF_text:TSF_text~'\n';  }
    }
    if( TSF_remove ){
        if( exists(TSF_path) ){  remove(TSF_path);  }
    }
    else{
      TSF_CTC_savedir(TSF_path);
      std.file.write(TSF_path,TSF_text);
    }
}

void TSF_CTC_writetext(string TSF_path, ...){    //#TSFdoc:TSF_pathにTSF_textを追記する。TSF_pathが存在しない場合新規作成。(TSFAPI)
    string TSF_text="";
    if( _arguments.length>0 && _arguments[0]==typeid(string) ){
      TSF_text=va_arg!(string)(_argptr);
      if( TSF_text.length>0 ){  TSF_text=TSF_text.back=='\n'?TSF_text:TSF_text~'\n';  }
    }
    TSF_CTC_savedir(TSF_path);
    if( exists(TSF_path) ){  std.file.append(TSF_path,TSF_text);  }else{  std.file.write(TSF_path,TSF_text);  }
}

string TSF_CTC_ESCencode(string TSF_textdup){    //#TSFdoc:「\t」を「&tab;」に置換。(TSFAPI)
    string TSF_text=TSF_textdup.replace("&","&amp;").replace("\t","&tab;");
    return TSF_text;
}

string TSF_CTC_ESCdecode(string TSF_textdup){   //#TSFdoc:「&tab;」を「\t」に戻す。(TSFAPI)
    string TSF_text=TSF_textdup.replace("&tab;","\t").replace("&amp;","&");
    return TSF_text;
}

string TSF_CTC_RPN(string TSF_RPN){    //#TSFdoc:逆ポーランド電卓。コンマを含む式は小数特化して高速化を図る。(TSFAPI)
    string TSF_RPNanswer="";
    real[] TSF_RPNstack=[];  real TSF_RPNstackL,TSF_RPNstackR,TSF_RPNstackF;
    string TSF_RPNnum="";  size_t TSF_RPNminus=0;  string[] TSF_RPNcalcND;
    string TSF_RPNseq=join([TSF_RPN.stripLeft(','),"  "]);
    switch( TSF_RPNseq.front ){
      case '+': TSF_RPNseq="p"~TSF_RPNseq[1..$]; break;
      case '-': TSF_RPNseq="m"~TSF_RPNseq[1..$]; break;
      case '*': TSF_RPNseq=""~TSF_RPNseq[1..$]; break;
      case '/': TSF_RPNseq="1|"~TSF_RPNseq[1..$]; break;
      case 'U': if( TSF_RPNseq[1]=='+' ){ TSF_RPNseq="$"~TSF_RPNseq[2..$]; } break;  //"U+"
      case '0': if( TSF_RPNseq[1]=='x' ){ TSF_RPNseq="$"~TSF_RPNseq[2..$]; } break;  //"0x"
      default:  break;
    }
    opeexit_rpn:
      foreach(char TSF_RPNope;TSF_RPNseq){
        if( count("0123456789abcdef.pm$|",TSF_RPNope) ){
            TSF_RPNnum~=TSF_RPNope;
        }
        else{}
      }
    if( TSF_RPNstack.length ){
        TSF_RPNstackL=TSF_RPNstack.back; TSF_RPNstack.popBack();
    }
    else{
        TSF_RPNstackL=0.0;
    }
        TSF_RPNanswer=to!string(TSF_RPNstackL);
    return TSF_RPNanswer;
}


unittest {
    string TSF_printlog="";
    std.stdio.writeln("unittest--- %s ---".format(__FILE__));
//    TSF_printlog=TSF_CTC_printlog("日本語テスト",TSF_printlog);
//    std.stdio.writeln(TSF_printlog);
//    string TSF_mdtext="";
//    TSF_mdtext=TSF_CTC_loadtext("README.md");
//    TSF_CTC_savetext("debug/README.txt",TSF_mdtext);
//    TSF_CTC_printlog(TSF_mdtext);
    TSF_CTC_printlog(TSF_CTC_RPN("1,2+"));
    
//    TSF_CTC_debug(TSF_CTC_argvs(["README.md","TSF_CalcTimeCode.d"]));
}


//#! -- Copyright (c) 2017-2018 ooblog --
//#! License: MIT　https://github.com/ooblog/TSF3KEV/blob/master/LICENSE
