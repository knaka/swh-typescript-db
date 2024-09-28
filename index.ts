import Database from "better-sqlite3";
import { getAuthor } from "./sqlcgen/query_sql"

const db = new Database("main.db");

async function main() {
  const user = await getAuthor(db, { id: 1 })
  if (user) {
    console.log(user)
  } else {
    console.log("User not found")
  }
}

main()
