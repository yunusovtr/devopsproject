Role Name
=========

This is an Ansible role for configuring an Ubuntu machine as a NAT gateway via Uncomplicated Firewall (UFW)

Requirements
------------

UFW, though the role will install it automatically.

Role Variables
--------------

The role uses facts to determine the main interface, then NATs to that, so there are no variables to configure.

----------------


    - hosts: gateways
      roles:
         - ssccio.ufw-nat

License
-------

MIT

Author Information
------------------

Ken Trenkelbach <ken@sscc.io>
