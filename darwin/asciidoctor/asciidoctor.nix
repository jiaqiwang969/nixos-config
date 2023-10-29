{ lib
, bundlerApp
, bundlerUpdateScript
, jre
}:

bundlerApp {
  pname = "asciidoctor";
  gemdir = ./.;

  exes = [
    "asciidoctor"
    "asciidoctor-pdf"
  ];

  buildInputs = [ jre ]; #for plantuml

  passthru = {
    updateScript = bundlerUpdateScript "asciidoctor";
  };

  meta = with lib; {
    description = "A faster Asciidoc processor written in Ruby";
    homepage = "https://asciidoctor.org/";
    license = licenses.mit;
    maintainers = with maintainers; [ gpyh nicknovitski ];
    platforms = platforms.unix;
  };
}
