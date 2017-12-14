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

char[string] TSF_CTC_PmzDiv;
auto TSF_CTC_PmzNum(string TSF_num){    //#TSFdoc:正負符号の抽出。(TSFAPI)
    long TSF_p=0,TSF_m=0,TSF_z=TSF_num.length;  char TSF_pmz='z';
    string[] TSF_numND;  char[] TSF_pmzND=['z','z'];  string TSF_pmzdiv="zz";
    if( count(TSF_num,'|') ){  TSF_numND=TSF_num.split("|")[0..2];  }else{  TSF_numND=[TSF_num,"z1"];  }
    foreach(size_t i;0..2){
      TSF_p=indexOf(TSF_numND[i],'p');  if( TSF_p<0 ){  TSF_p=TSF_numND[i].length;  }
      TSF_m=indexOf(TSF_numND[i],'m');  if( TSF_m<0 ){  TSF_m=TSF_numND[i].length;  }
      TSF_z=indexOf(TSF_numND[i],'z');  if( TSF_z<0 ){  TSF_z=TSF_numND[i].length;  }
      if( (TSF_p<TSF_m)&&(TSF_p<TSF_z) ){  TSF_pmzND[i]='p';  }
      if( (TSF_m<TSF_p)&&(TSF_p<TSF_z) ){  TSF_pmzND[i]='m';  }
      if( (TSF_z<TSF_p)&&(TSF_z<TSF_m) ){  TSF_pmzND[i]='z';  }
      TSF_numND[i]=TSF_numND[i].replace("p","").replace("m","").replace("z","").replace(" ","");
    }
    TSF_pmzdiv=to!string(TSF_pmzND[0])~to!string(TSF_pmzND[1]);
    TSF_CTC_PmzDiv=["pp":'p',"pm":'m',"pz":'p',"mp":'m',"mm":'p',"mz":'m',"zp":'z',"zm":'z',"zz":'z'];
    if( TSF_pmzdiv in TSF_CTC_PmzDiv ){  TSF_pmz=TSF_CTC_PmzDiv[TSF_pmzdiv]; }else{  TSF_pmz='z';  }
    return Tuple!(char,string,string)(TSF_pmz,TSF_numND[0],TSF_numND[1]);
}

string TSF_CTC_RPNZERO="N";
string TSF_CTC_RPN(string TSF_RPN){    //#TSFdoc:逆ポーランド電卓。コンマを含む式は小数特化して高速化を図る。(TSFAPI)
    string TSF_RPNanswer="";
    dchar[] TSF_RPNpmzstack=[];  dchar TSF_RPNpmzstackL='z',TSF_RPNpmzstackR='z',TSF_RPNpmzstackF='z';
    real[] TSF_RPNnumstack=[];  real TSF_RPNnumstackL=0.0,TSF_RPNnumstackR=0.0,TSF_RPNnumstackF=0.0;
    string TSF_RPNnum="";  string[] TSF_RPNcalcND;  real TSF_RPNcalcN,TSF_RPNcalcD;
    long TSF_RPN_p=0,TSF_RPN_m=0,TSF_RPN_z=0;  char TSF_RPN_pmz='z';
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
        if( count("0123456789abcdef.pmz$|",TSF_RPNope) ){
          TSF_RPNnum~=TSF_RPNope;
        }
        else{
          TSF_RPN_z=TSF_RPNnum.length;
          if( TSF_RPNnum.length>0 ){
            auto TSF_CTC_PmzNum_Tuple=TSF_CTC_PmzNum(TSF_RPNnum);
            TSF_RPN_pmz=TSF_CTC_PmzNum_Tuple[0];
            try{
              TSF_RPNcalcN=to!real(TSF_CTC_PmzNum_Tuple[1]);  TSF_RPNcalcD=to!real(TSF_CTC_PmzNum_Tuple[2]);
            }
            catch(ConvException e){
              TSF_RPNanswer=TSF_CTC_RPNZERO;
              break;
            }
            if( TSF_RPNcalcD!=0.0 ){
              TSF_RPNnumstack~=TSF_RPNcalcN/TSF_RPNcalcD;
              TSF_RPNpmzstack~=TSF_RPN_pmz;
            }
            else{
              TSF_RPNanswer=TSF_CTC_RPNZERO;
              break;
            }
            TSF_RPNnum="";
          }
//          if( count("SCTsrtRELl",TSF_RPNope) ){
//          if( count("+-*/\\_#%<>AH^,TSF_RPNope) ){
//          if( count("QqOoUu",TSF_RPNope) ){
//          if( count("!SCTsrtRELl",TSF_RPNope) ){
        }
      }
    if( TSF_RPNnumstack.length ){
      TSF_RPNnumstackL=TSF_RPNnumstack.back; TSF_RPNnumstack.popBack();
      TSF_RPNpmzstackL=TSF_RPNpmzstack.back; TSF_RPNpmzstack.popBack();
    }
    else{
      TSF_RPNnumstackL=0.0;
      TSF_RPNpmzstackL='z';
    }
    if( TSF_RPNanswer != TSF_CTC_RPNZERO ){
      TSF_RPNanswer=to!char(TSF_RPNpmzstackL)~to!string(TSF_RPNnumstackL);
    }
    return TSF_RPNanswer;
}

string TSF_CTC_CalcZERO="N|0";


unittest {
    string TSF_printlog="";
    std.stdio.writeln("unittest--- %s ---".format(__FILE__));
//    TSF_printlog=TSF_CTC_printlog("日本語テスト",TSF_printlog);
//    std.stdio.writeln(TSF_printlog);
//    string TSF_mdtext="";
//    TSF_mdtext=TSF_CTC_loadtext("README.md");
//    TSF_CTC_savetext("debug/README.txt",TSF_mdtext);
//    TSF_CTC_printlog(TSF_mdtext);
    TSF_CTC_printlog(TSF_CTC_RPN("p1,p2+"));
    TSF_CTC_printlog(TSF_CTC_RPN("p1.5,p2|3+"));
    
//    TSF_CTC_debug(TSF_CTC_argvs(["README.md","TSF_CalcTimeCode.d"]));
}


//#! -- Copyright (c) 2017-2018 ooblog --
//#! License: MIT　https://github.com/ooblog/TSF3KEV/blob/master/LICENSE
