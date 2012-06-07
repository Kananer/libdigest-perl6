module Digest::rmd160;
use Digest::util;

constant r1 = <
    0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
    7 4 13 1 10 6 15 3 12 0 9 5 2 14 11 8
    3 10 14 4 9 15 8 1 2 7 0 6 13 11 5 12
    1 9 11 10 0 8 12 4 13 3 7 15 14 5 6 2
    4 0 5 9 7 12 2 10 14 1 3 8 11 6 15 13
>;
constant r2 = <
    5 14 7 0 9 2 11 4 13 6 15 8 1 10 3 12
    6 11 3 7 0 13 5 10 14 15 8 12 4 9 1 2
    15 5 1 3 7 14 6 9 11 8 12 2 10 0 4 13
    8 6 4 1 3 11 15 0 5 12 2 13 9 7 10 14
    12 15 10 4 1 5 8 7 6 2 13 14 0 3 9 11
>;
constant s1 = <
    11 14 15 12 5 8 7 9 11 13 14 15 6 7 9 8
    7 6 8 13 11 9 7 15 7 12 15 9 11 7 13 12
    11 13 6 7 14 9 13 15 14 8 13 6 5 12 7 5
    11 12 14 15 14 15 9 8 9 14 5 6 8 6 5 12
    9 15 5 11 6 8 13 12 5 12 13 14 11 8 5 6
>;
constant s2 = <
    8 9 9 11 13 15 15 5 7 7 8 11 14 14 12 6
    9 13 15 7 12 8 9 11 7 7 12 7 6 15 13 11
    9 7 15 11 8 6 6 14 12 13 5 14 13 13 7 5
    15 5 8 11 14 14 6 14 6 9 12 9 12 5 15 8
    8 5 12 9 12 5 14 6 8 13 6 5 15 13 11 11
>;
sub f($j, $x, $y, $z) {
    return
    $j < 16 ?? $x +^ $y +^ $z !!
    $j < 32 ?? ($x +& $y) +| (+^$x % 2**32 +& $z) !!
    $j < 48 ?? ($x +| +^$y % 2**32) +^ $z !!
    $j < 64 ?? ($x +& $z) +| ($y +& (+^$z % 2**32)) !!
    $j < 80 ?? $x +^ ($y +| +^$z % 2**32) !!
    !!! "out of range";
}
sub K1($j) {
    return
    $j < 16 ?? 0x00000000 !!
    $j < 32 ?? 0x5a827999 !!
    $j < 48 ?? 0x6ed9eba1 !!
    $j < 64 ?? 0x8f1bbcdc !!
    $j < 80 ?? 0xa953fd4e !!
    !!! "out of range";
}
sub K2($j) {
    return
    $j < 16 ?? 0x50a28be6 !!
    $j < 32 ?? 0x5c4dd124 !!
    $j < 48 ?? 0x6d703ef3 !!
    $j < 64 ?? 0x7a6d76e9 !!
    $j < 80 ?? 0x00000000 !!
    !!! "out of range";
}
our proto bin($) {*}
multi bin(Str $s) returns Buf { bin Buf.new: $s.ords }
multi bin(Buf $data) returns Buf {
    my @word = Digest::util::bytesToLWords my @b = $data.list;
    my $len = @b * 8;

    @word[$len +> 5] +|= 0x80 +< ($len % 32);
    @word[((($len + 64) +> 9) +< 4) + 14] = $len;

    my @h = 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476, 0xc3d2e1f0;
    loop (my int $i = 0; $i < @word; $i = $i + 16) {
	my @X = my @Y = @h;
	loop (my $j = 0; $j < 80; $j = $j + 1) {
	    my $T = rotl(
		@X[0] m+ f($j, |@X[1..3]) m+ (@word[$i+r1[$j]] // 0) m+ K1($j),
		s1[$j]
	    ) m+ @X[4];
	    @X = @X[4], $T, @X[1], rotl(@X[2], 10) % 2**32, @X[3];
	    $T = rotl(
		@Y[0] m+ f(79-$j, |@Y[1..3]) m+ (@word[$i+r2[$j]] // 0) m+ K2($j),
		s2[$j]
	    ) m+ @Y[4];
	    @Y = @Y[4], $T, @Y[1], rotl(@Y[2], 10) % 2**32, @Y[3];
	}
	@h = @h[1..4,^1] Z[m+] @X[2..4,^2] Z[m+] @Y[3..4,^3];
    }
    return Buf.new: Digest::util::lWordsToBytes @h;
}
our sub hex($data) returns Str { [~] bin($data).list».fmt("%02x") }

# vim: ft=perl6
