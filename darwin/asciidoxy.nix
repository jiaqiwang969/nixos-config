{ buildPythonApplication
, lib
, fetchPypi
, json5
, tqdm
, mako
, toml
, aiohttp
, pyparsing 
, six
}:


let

  packaging_20_3 = buildPythonApplication rec {
    pname = "packaging";
    version = "20.3";
  
    src = fetchPypi {
      inherit pname version;
      sha256 = "sha256-PCkrR0/aFnHsV9Rtc50HK/1JWk9RrQGgVRIdgelSt6M=";
    };

    doCheck = false;

    propagatedBuildInputs = [ pyparsing six ];
  };


in
buildPythonApplication rec {
  pname = "asciidoxy";
  version = "0.8.7"; # Fill in your version here

  src = fetchPypi {
    pname = "asciidoxy";
    inherit version;
    sha256 = "sha256-GU0aYqtqMMCH2vv9hqwtjCCcRT2qjSBkviRD0121PE4=";
  };


  propagatedBuildInputs = [
    tqdm
    mako
    toml
    packaging_20_3
    aiohttp
  ];


  doCheck = true;
  checkPhase = "$out/bin/asciidoxy --help 1>/dev/null";

  meta = with lib; {
    homepage = "https://www.asciidoxy.org/";
    description = "AsciiDoxy let’s you generate beautiful documentation using the combined power of AsciiDoc and Python.";
    license = lib.licenses.mit;
  };
}

