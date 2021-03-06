# プログラミング言語「TSF_Tab-Separated-Forth」開発準備(開発拠点は「TSF3」に移動)。

「KanEditVim」が「[KanjiInputVim](https://github.com/ooblog/KIV "漢字直接入力＆漢字直接検索Vimプラグイン「KanjiInputVim」(準備中)。 ")」に名称変更したので、TSFのリポジトリも「[TSF3](https://github.com/ooblog/TSF3 "プログラミング言語「TSF_Tab-Separated-Forth」開発準備(ver3草案)。")」に変更し、密結合から疎結合にしました。  

## TSF超ザックリ説明。

TSFはForth風インタプリタです。構文は文字列をタブで区切るだけ(コメント行と関数カードでシバン「#!」を用いる程度)。  
名前の由来はCSV→TSV→TSF。  
![TSF syntax image](https://github.com/ooblog/TSF2KEV/blob/master/docs/TSF_512x384.png "TSF2KEV/TSF_512x384.png at master ooblog/TSF2KEV")  
ver3開発前につき上記画像はver2「[TSF2KEV(https://ooblog.github.io/TSF2KEV/)](https://ooblog.github.io/TSF2KEV/ "「TSF2KEV」はプログラミング言語「TSF_Tab-Separated-Forth」のD言語とPythonによる実装です。")」のものになります。  

## 既存のFORTHおよびその他のプログラミング言語と違う所。

関数の事をワードではなくカードと呼びます。カードの束をスタックと呼びます。スタックの集まりをデッキと呼びます。  
TSF構文と数式(電卓)を分離してます。それにより電卓カード「#!TSF_Calc」に渡す数式内では括弧が使えるので中置記法(分数)とRPN(小数)を使い分けできます。  
逆にTSF構文からは括弧を除外しています。なのでIF文やFOR文が存在しません。IF文は電卓内の条件演算子を用い、FOR文は再帰を用います。  

## 言語が生まれた経緯。

漢直(漢字直接入力)の漢字配列やkan5x5フォントのグリフエディタの単漢字辞書など漢字データ管理でTSV(LTSVを更にアレンジしたL:Tsv)を用いてました(「[LTsv10kanedit](https://github.com/ooblog/LTsv10kanedit "ooblog/LTsv10kanedit: 「L:Tsv」の読み書きを中心としたモジュール群と漢字入力「kanedit」のPythonによる実装です(準備中)。")」を参考)。  
実装を[HSP](http://hsp.tv/ "HSPTV!（HSP( Hot Soup Processor )ソフトウェアの配布）")→[BaCon](http://www.basic-converter.org/ "BaCon - BASIC to C converter")→[Python](https://www.python.org/ "Welcome to Python.org")で何度か作り直す紆余曲折を経て今度は[D言語](https://dlang.org/ "Home - D Programming Language")で作り直す流れでしたが、言語の変更が強いられる度に一から作り直すのはしんどい。  
なので、TSVにデータ(プログラム含む)を入力するだけで動作するスクリプトが欲しくなったので開発中です。  
プログラム本体をTSFで作れば、OSや言語などの環境差異はTSF実装の方で吸収させるという戦法を想定。  
当面の目標は「[TSF2KEV/kanedit.vim](https://github.com/ooblog/TSF2KEV/blob/master/KEV2/kanedit.vim "TSF2KEV/kanedit.vim at master ooblog/TSF2KEV")」のような漢直をVimスクリプトの力を借りずに使わずに「TSF」だけで動かす事。  

## 文法の見直し(3ver文法)。よりシンプルな構文を目指す。

☐「#!」で始まる行(スタック)はコメント。「#!TSF_」で始まるカードは関数予約。  
☐関数カード名に直接THisTHatTHeTHeyを埋め込んでたのを廃止。「#!TSF_This」「#!TSF_That」関数カードが返り値すればよい。  
　(#!TSF_theyは0文字列を返す。0文字列カードはスタック名一覧)。  
☐関数カードの末尾「C」はThatカード1枚処理、末尾「N」はThatカードN枚処理、末尾「L」はThatカードL回処理、末尾「S」はTheスタック処理。  
☐スタック表示指定「#!TSF_StyleC」のOTNstyleの代わりに数値指定。0の時はOneLiner。マイナスの時は右から読む縦書きに変換。  
☐KanEditVimのためにL:Tsvとの互換性(ラベル指定も対応)維持。  

## 電卓の見直し(3ver文法)。符号必須化。

☐「#!TSF_Calc」と「#!TSF_RPN」の統合(既にver2の時点で分数計算か小数計算かはコンマの有無で判定)。小数計算時でもinfを「pN」と表示。  
☐数列和「M」などの部分で[スタック名]を指定する事で数列も扱いたい。  
☐数式の構文解析高速化のためpmzの符号を必須。これにより「p(m1)→pm1z→p1」の様に絶対値の式が符号処理に吸収できる。  
☐絶対値は正の符号ではないので、「m2+z3」はp1ではなく「m5」になる。符号は左辺に影響を受ける。絶対値に加減算等しても絶対値のまま。  
☐無限大にも符号を搭載(pn|0,mn|0)。これによりmn|0でスタックの先頭、pn|0でスタックの末尾といった指定を可能に。  
☐0にも符号(マイナスゼロm0の導入)。これによりスタック逆順がm1からではなくm0からにできる。  
☐p0/p0およびpn/pnその他pn-pnなど計算不能な場合は絶対値の無限「zn」と表現。  
☐漢数字や符号の+-変換などは別途「#!TSF_Format」を用いる予定。  
☑日時を分母86400秒の分数で扱う事により電卓に統合したい(RPNで暫定的にUNIX時間に対応ただし浮動小数有効桁数の関係で「日u」「時t」が同時に扱えない)。  
☐単純な文字列連結も電卓に統合したい(複雑な文字列処理は正規表現を用いる)。  

## コールスタックの見直し(3ver文法)。ループの簡易化。

☐「#!TSF_CallN」「#!TSF_CallS」を追加予定。コールスタックはスタック名一覧に加え「回数」も保持させる。  

## その他TSF2KEVから引きずってる未解決な箇所など。

☐「tan(θ&#42;p90|z360)」を分母ゼロ「pN|0」と表記したいがとりあえず未着手。  
☐字列の類似度(matcHer)がD言語で再現できるか未定なので当面後回しになるかも。  
☐D言語で現在時刻(StopWatchではなく「現在時刻」)のミリ秒以下を取得する方法が不明なので「@ls」「@rs」系がとりあえず0を返す。  

## 開発環境対応言語について(開発環境はXenialPup7.5に変更予定なのでPython2系の互換は無くなるかも)。

☑Tahrpup6.0.5,Wine1.7.18共にdmd2.077.1で開発。  
☐D言語以外のプログラム言語はTSFで作ったテンプレートを元にジェネレータで変換する予定。  
☐PythonやVimのバージョンはXenialPupに移行するまで未定(Tahrpup6.0.5ではPython2.7.6,vim.gtk7.4.52)。  

* Tahrpup6.0.5(Puppy Linux)
    * [http://puppylinux.com/](http://puppylinux.com/ "Puppy Linux Home")
* Python 3.4.4
    * [https://www.python.org/downloads/release/python-344/](https://www.python.org/downloads/release/python-344/ "Python Release Python 3.4.4 | Python.org")
* DMD 2.074.0
    * [https://dlang.org/download.html](https://dlang.org/download.html "Downloads - D Programming Language")
* vim-gtk(Ubuntu trusty)
    * [https://packages.ubuntu.com/trusty/vim-gtk](https://packages.ubuntu.com/trusty/vim-gtk "Ubuntu – trusty の vim-gtk パッケージに関する詳細")
* Vim — KaoriYa
    * [https://www.kaoriya.net/software/vim/](https://www.kaoriya.net/software/vim/ "Vim — KaoriYa")
* Portable Wine(shinobar.server-on.net)
    * [http://shinobar.server-on.net/puppy/opt/wine-portable-HELP_ja.html](http://shinobar.server-on.net/puppy/opt/wine-portable-HELP_ja.html "Portable Wine")

## ライセンス・著作権など。

&#35;! -- Copyright (c) 2017 ooblog --  
&#35;! License: MIT　https://github.com/ooblog/TSF3KEV/blob/master/LICENSE  
