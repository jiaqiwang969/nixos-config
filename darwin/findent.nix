{ stdenv, fetchFromGitHub, lib }:  # Add 'lib' here

let
  source = fetchFromGitHub {
    owner = "wvermin";
    repo = "findent";
    rev = "85c8225be6f526a47bc9ed6794a36ba7b522b90c";
    sha256 = "QGInRMX7aXP6mnmLvkPPiOnJ0ij8wx3+v2othozge7Q=";
  };
in
stdenv.mkDerivation {
  pname = "findent";
  version = "4.2.1";

  src = source + "/findent";

  meta = with lib; {  # Now we are using the 'lib' we added above
    homepage = "https://www.ratrabbit.nl/ratrabbit/findent/index.html";
    description = "Formatter for Fortran code.";
    license = licenses.bsd3;  # This should correctly refer to the BSD 3-Clause license
  };
}

