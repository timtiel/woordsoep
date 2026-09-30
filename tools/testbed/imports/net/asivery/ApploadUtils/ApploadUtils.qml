// Mock van de module net.asivery.ApploadUtils.
// Op de tablet levert AppLoad deze module; op de pc niet.
// De app importeert de module maar gebruikt er (nog) niets uit, dus
// deze lege stub is genoeg om het importeren te laten slagen.
pragma Singleton
import QtQuick

QtObject {
}
