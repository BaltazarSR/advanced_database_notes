# SQL Tables & Relationships

## My understanding
Think of a SQL table as the digital equivalent of a **highly organized spreadsheet tab**. It is the fundamental building block of a relational database where data is stored in a structured format. 

A table is defined by a specific set of **columns** (which represent the type of data, like "Email" or "Price") and **rows** (which represent individual entries or records, like a specific customer or a single transaction). Unlike a flexible spreadsheet, however, a SQL table is strict: every piece of data in a column must follow the same rules and data types.

## Why it matters
Tables are the backbone of data integrity. Without them, data would just be a chaotic pile of text. They matter because:

* **Relational Logic:** By using multiple tables, you can link data together without repeating information.
* **Scalability:** They allow databases to handle millions of rows while maintaining fast search speeds through indexing.
* **Consistency:** They enforce "schemas," ensuring that no one accidentally types a name into a field meant for a phone number.

---

## Example: Relational Tables

To understand how tables "talk" to each other, let’s look at a Bookstore database with two connected tables: `Books` and `Orders`.

### 1. Table: `Books` (The Master List)
| BookID (**PK**) |      Title       | Price |
| :-------------- | :--------------- | :---- |
|       101       | The Great Gatsby | 15.99 |
|       102       |      1984        | 12.50 |

### 2. Table: `Orders` (The Transactions)
| OrderID (**PK**) | **BookID (FK)** |  CustomerName |  OrderDate |
| :--------------- | :-------------- | :------------ | :--------- |
|       5001       |      **101**    |  Alice Smith  | 2026-02-15 |
|       5002       |      **102**    |   Bob Jones   | 2026-02-16 |
|       5003       |      **101**    | Charlie Brown | 2026-02-17 |

---

## Key Terms ("The Stuff")

* **Primary Key (PK):** A unique identifier for every record in a table (like a Social Security number). In the `Books` table, `BookID` is the PK. No two books can have the same ID.
* **Foreign Key (FK):** A column in one table that points to the Primary Key in another table. In the `Orders` table, `BookID` is a **Foreign Key**. It "links" the order to a specific book in the master list.
* **Relationships:**
    * **One-to-Many:** This is the most common. One book (PK) can appear in many different orders (FK).
    * **Many-to-Many:** Like Students and Classes; one student has many classes, and one class has many students. This usually requires a third "junction table" to link them.
* **Constraints:** Rules applied to columns (e.g., `NOT NULL` means the field cannot be left empty, `UNIQUE` means no duplicates allowed).


-- Review update