# @version 0.3.7
system: address


@external
def __init__(_system: address):
    self.system = _system


@external
def launchSystem(_owner: address) -> address:
    new_system: address = create_forwarder_to(
        self.system, convert(_owner, bytes[32])
    )
    return new_system
