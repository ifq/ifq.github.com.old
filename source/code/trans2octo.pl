#!/usr/bin/perl
# 用法：
# trans2octo.pl blog_index.html
# 将blog目录下的baidu博客转换为octopress格式的博客，存入tmp文件夹。
# 文章中的img图片标签会自动替换为octopress格式，指向本地$IMGDIR目录下。
# 同时会生成imglist.log记录所有图片url，可使用 wget -i imglist.log
# 下载到本地，保存至$IMGDIR目录。
# [2012-09-10 一] IFQ

use   File::Path;

# match汉字用，不想加载其他库，还有什么好做法？
$HZ = "[\x80-\xFF][\x80-\xFF].*?";
# YAML Head
$PRE = "---\nlayout: post\ntitle: \"XXXTXXX\"\ncomments: true\ncategories: [legacy]\n---\n\n";
# 替换img字符串
$IMG = "{% img XXXPIC 800 %}";
# img 文件夹位置
$IMGDIR = "/rc/legacy/";

# 创建临时文件夹
if(!-e "tmp") {
	print "create tmp dir.\n";
	mkdir "./tmp";
}

while(<>) {

	@links = $_ =~ /\<a(.*?)\<\/a\>/g;

	open IMGLIST, ">./imglist.log" || die "open imglist fail.";

	foreach (@links) {
		if (/(\.\/blog\/.*?html).*?(\d{4})$HZ(\d{1,2})$HZ(\d{1,2}).* ($HZ)$/) {
			$cnt = 1;

			# 防止重名加cnt
			while(-e ($tgt = "./tmp/$2-$3-$4-$cnt.html")) {
				$cnt++;
			}

			open (origin, "<$1") || next; #die ("Could not open file $1");
			open (target, ">$tgt") || die ("Could not open file $tgt");
			print "$1 --> $tgt : ";
			# start trans
			while(<origin>) {
				# get blog title
				if (/\<title\>(.*)\<\/title\>/) {
					$tmp_pre = $PRE;
					$title = $1;
					$tmp_pre =~ s/XXXTXXX/$title/;
					print target $tmp_pre;
				}

				# del content before <body>
				$_ =~ s/^.*\<body\>//;
				# del content after </body>
				$_ =~ s/\<\/body\>.*$//;
				# del h1 title
				$_ =~ s|\<h1\>.*?\<\/h1\>||;

				# trans <img> to {% img %}
				@imgs = $_ =~ /\<img .*?src="(.*?)".*?\>/;
				foreach $img_itr (@imgs) {
					$tmp_img = $IMG;
					$url = $img_itr;
					$url =~ s/http.*\//$IMGDIR/;
					$tmp_img =~ s/XXXPIC/$url/;
					$_ =~ s/\<img .*src="$img_itr".*?\>/$tmp_img/g;
					print IMGLIST "$img_itr\n";
				}

				# write to file
				print target $_;
			}

			close origin;
			close target;
			print "done.\n";
		} else {
			print "$_ trans fail\n";
		}
	}

	close IMGLIST;
}

