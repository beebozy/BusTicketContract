// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";



const TicketModule = buildModule("LockModule", (m) => {
 

  const Ticket = m.contract("Tiket");

  return { Ticket };
});

export default TicketModule;
