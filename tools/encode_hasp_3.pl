#!/usr/bin/perl -w

use strict;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin";

use HASPTools;

use constant VCODE => "RrDWHrAqOELsGKzcoZ8840pCHdOpTaTFi8EQJgD0fSMi+ax2dw3VB+UeL9XGHpJdBkpaxWzAHvw+XHBkhbzxoJ8vWAwHznWnKfC7GJQgW4g3EAd+Bs0pDvGhN6zVBfVSS6yZvC7JecbOLrtdaAEMXtb+sqACsoCDU1D5Bm6I94etRtXvlTgoQaBCEyuobowBEsp5KUCJKBvGOvJRqd2V0hsoYDTRMuBe6i/JU9Hki8LjB5W+frh1/jmZVgKslS3kEFRBhB/bjbQApCBHh87RSmwaqa53Ua6ik6Ck7wVh+W7NicKC2NFqz4d8/Po9RLbOul1DqregJeM9e4z7AL1VtelLnMPHWMgs5qYYfg9SlTYMSdvWZedINo0bp5rRonQwWoBR7GxlsodAbDMlRnDGINlNHeMhxa9kkOgFps387DuRzm0yaA2lA1zu9E+jvTIcNqVk66TYGzvNhc4CTIYjmfWXNRxIusdf6dXyIxGvI8jdZ0guWj4t98o1N1jtebzamLDVy4Tv4pHNsbZx6ydzJpztUArRmlNgztbAxHKsMNHTfKqXkOi5LrWQZNfmXltsN6wVhROvemGslUIxkaclOGra8IA0PRUpaUdAQXak4UiGIrydCd09YgkKK6fQOf7gW0aHmuOg21lgT5qqUUxn0+R3JWA2ICRszPUOA6tYdFDE5K3obJN2Mb7bNrBZ/kOACeikAdJgxc96hmBxmDJ71mGGY30gS1+eLyL+feaQ7wMZpJZSVG5RqGQ2Y/41M7ds/Qg97qyAUifGvtKpJtFTA+/TJ5emuQzM/LAR3FYiDpyEWzew9yUDpmcPsMxje9qYQNL67td+wrv2ukZkIfPJIvcls8h+oam5xcyMcnYDhAIm4R9kIz4pqvI/BjoqwZV7rb9sbsVWFhG9UHPqM7ITl1101vIDaXU1DKgB1udhzuI=";
use constant PASS1 => 23127;
use constant PASS2 => 24848;

sub encode_data {
	my $data = shift;
	my $res = HASPTools::EncodeData($data);
	if($res != 0) {
		print "HASP error: $res\n";
		exit(1);
	}
	return $data;
}


if(HASPTools::Detect eq 'HASP4') {
	HASPTools::Init(PASS1, PASS2);
} else {
	HASPTools::Init(VCODE);
}

if(@ARGV < 2) {
	print qq|usage: encode_hasp_3 <src file name> <dst file name>\n|;
	exit;
}
my $filename = $ARGV[0];
open F, $filename or die "Can't open file $filename for reading: $!";
$/ = '';
my $data = <F>;
close F;
my $enc_data = encode_data($data);
$filename = $ARGV[1];
open F, ">$filename" or die "Can't open file $filename for writing: $!";
binmode F;
print F $enc_data;
close F;
