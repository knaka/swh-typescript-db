import Database from "better-sqlite3";
import { getUser } from "./sqlcgen/query_sql"

const db = new Database("main.db");

async function main() {
  const user = await getUser(db, { id: 100, nullableId: 1 })
  if (user) {
    console.log(user)
  } else {
    console.log("User not found")
  }
}

main()
