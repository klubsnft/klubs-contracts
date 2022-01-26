import { solidityKeccak256 } from "ethers/lib/utils";

export class VerID {
    vIDlist: string[] = [];

    addVID(verificationID: string) {
        this.vIDlist.push(verificationID);
    }

    removeVID(verificationID: string) {
        const length = this.vIDlist.length;
        if (length == 0) {
            throw new Error("VID length : 0");
        }
        let targetId = 0;

        for (let i = 0; i < length; i++) {
            if (this.vIDlist[i] == verificationID) {
                targetId = i;
                break;
            }

            if (i == length - 1) {
                throw new Error("VID remove failure");
            }
        }

        this.vIDlist[targetId] = this.vIDlist[length - 1];
        this.vIDlist.pop();
    }
}

export class UserOnSaleAmount {
    amount: number[][];

    constructor(items: number, itemIds: number) {
        this.amount = Array.from(Array(items), () => Array(itemIds).fill(0));
    }

    addAmount(item: number, id: number, amount: number) {
        this.amount[item][id] = this.amount[item][id] + amount;
    }

    subAmount(item: number, id: number, amount: number) {
        if (this.amount[item][id] < amount) throw new Error("subAmount failure");
        this.amount[item][id] = this.amount[item][id] - amount;
    }
}

export interface Sale {
    seller: string;
    metaverseId: number;
    item: string;
    id: number;
    amount: number;
    unitPrice: number;
    partialBuying: boolean;
}

export function makeSaleVerificationID(sale: Sale, nonce: number) {
    return solidityKeccak256(
        ["address", "uint256", "address", "uint256", "uint256", "uint256", "bool", "uint256"],
        [sale.seller, sale.metaverseId, sale.item, sale.id, sale.amount, sale.unitPrice, sale.partialBuying, nonce]
    );
}
