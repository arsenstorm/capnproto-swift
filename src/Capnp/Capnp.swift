import CapnpCLib

public enum Capnp {
    public static var version: (major: Int, minor: Int, micro: Int) {
        (
            major: Int(capnp_c_version_major()),
            minor: Int(capnp_c_version_minor()),
            micro: Int(capnp_c_version_micro())
        )
    }
}
