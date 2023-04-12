ROUTINE Strix.SCM [Type=INC]
#include Strix

#; ===== Dot-separated string macro's

/// The final piece of a dot-separated item
#define ItemType(%item) $Piece(%item, ".", $Length(%item, "."))

/// Returns the lowercase last piece of a dot-separated string.
#define NormalizedType(%item) $ZConvert($$$ItemType(%item), "l")

/// All but the final piece of a dot-separated string
#define ItemName(%item) $Piece(%item, ".", 1, $Length(%item, ".")-1)

/// Convert the final piece of a dot-separated string to lowercase (in-place)
#define NormalizeType(%item) Set $$$ItemType(%item)=$ZConvert($$$ItemType(%item),"l")


