#Requires AutoHotkey v2+
#Include JSON.ahk

class EC2 {
    static prefixes := []

    /**
     * Initializes the EC2 range cache from a JSON file.
     * @param {string} jsonPath Path to the ip-ranges.json file.
     */
    static Initialize(jsonPath) {
        if !FileExist(jsonPath)
            return false

        try {
            content := FileRead(jsonPath)
            data := JSON.Load(content)
            this.prefixes := []

            if !data.Has("prefixes")
                return false

            for item in data["prefixes"] {
                if item.Has("service") && item["service"] == "EC2" && item.Has("ip_prefix") {
                    cidrParts := StrSplit(item["ip_prefix"], "/")
                    if cidrParts.Length != 2
                        continue

                    ip := cidrParts[1]
                    maskLength := Integer(cidrParts[2])

                    this.prefixes.Push({
                        numeric: this.IPv4ToNumber(ip),
                        mask: this.CIDRToMask(maskLength),
                        region: item.Has("region") ? item["region"] : "unknown"
                    })
                }
            }
            return true
        } catch Any as e {
            return false
        }
    }

    /**
     * Resolves the AWS region for a given IPv4 address.
     * @param {string} ip The IPv4 address to check.
     * @returns {string} The region name or "Unknown".
     */
    static GetRegion(ip) {
        try {
            ipNum := this.IPv4ToNumber(ip)
            for prefix in this.prefixes {
                if (ipNum & prefix.mask) == (prefix.numeric & prefix.mask)
                    return prefix.region
            }
        }
        return "Unknown"
    }

    static IPv4ToNumber(ip) {
        parts := StrSplit(ip, ".")
        if parts.Length != 4
            return 0
        return (Integer(parts[1]) << 24) | (Integer(parts[2]) << 16) | (Integer(parts[3]) << 8) | Integer(parts[4])
    }

    static CIDRToMask(cidr) {
        if cidr <= 0
            return 0
        if cidr >= 32
            return 0xFFFFFFFF
        return (0xFFFFFFFF << (32 - cidr)) & 0xFFFFFFFF
    }
}
