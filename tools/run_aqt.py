#!/usr/bin/env python3
"""Start 'aqt' via de Windows-certificaatopslag (truststore).

Sommige machines (o.a. met TLS-inspectie/antivirus) laten Python's eigen
certificaatcontrole falen op download.qt.io, terwijl PowerShell/curl er wel
bij kunnen. Dit hulpje laat Python dezelfde certificaatopslag gebruiken als
Windows zelf.

Gebruik (voorbeeld):
  py tools/run_aqt.py install-qt windows desktop 6.6.3 win64_msvc2019_64 --archives qtbase --outputdir .qt
"""
import sys


def main():
    try:
        import truststore
    except ImportError:
        print("truststore ontbreekt: py -m pip install truststore", file=sys.stderr)
        return 1
    truststore.inject_into_ssl()

    from importlib.metadata import entry_points

    eps = list(entry_points(group="console_scripts", name="aqt"))
    if not eps:
        print("aqtinstall ontbreekt: py -m pip install aqtinstall", file=sys.stderr)
        return 1
    return eps[0].load()() or 0


if __name__ == "__main__":
    sys.exit(main())
