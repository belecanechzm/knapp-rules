# Host Communication Workflow (KISOFT_XML / HostPretender)

This workflow explains how to locally send and validate host messages for KiSoft One using the active KISOFT_XML SOAD channels defined in `wcs/lager/cfg/hostapp.xml` and the `HostPretender` utility. Only localhost simulation is covered (no external hosts). It includes message catalog, templates, placeholder system, helper scripts, validation strategy, and extension guidelines.

---

## 1. Active Channels (from hostapp.xml)

| Channel   | Transport | Syntax      | Direction  | Purpose                                  |
|-----------|-----------|-------------|------------|------------------------------------------|
| SOAD_IN   | SOAD      | KISOFT_XML  | Inbound    | Host → One (business & master data)      |
| SOAD_OUT  | SOAD      | KISOFT_XML  | Outbound   | One → Host (acknowledgements, statuses)  |
| SNAP_OUT  | FILE      | KISOFT_XML  | Outbound   | Snapshot file generation (status, stock) |

List dynamically:
```
tools/hcom/hostpret_list_channels.sh
```
(Uses `HostPretender -L` and formats output.)

---

## 2. Message Categories

### 2.1 Inbound Business / Master Data (sent TO KiSoft One via `SOAD_IN`)
| RecordType (XML Root) | Description |
|-----------------------|-------------|
| CreateProducts        | Insert new product + channel configuration |
| UpdateProducts        | Update / delete product-channel info |
| CreateCustomers       | Insert customers |
| UpdateCustomers       | Update / delete customers |
| CreateRoutes          | Insert routes |
| UpdateRoutes          | Update / delete routes |
| GoodsIn               | Goods in / tote reception incl. slot capacities |
| InventoryOrder        | Initiate inventory count |
| CreateCustomerOrder   | Create picking / customer order |
| HOSTPickStatus        | (Host initiated status injection scenarios) |
| LockUnlockProduct     | Lock / unlock product variations |
| StorageCounting       | Manual counting submission |
| Snapshot              | Request snapshot generation (type attribute) |
| UserDownload          | Download user master data |

### 2.2 Outbound Acknowledgements (received FROM KiSoft One on `SOAD_OUT`)
For each inbound message there is normally a `...Reply` or `...StatusReply` (or empty generic reply). Examples:
| Reply Root                | Triggered By             |
|---------------------------|--------------------------|
| CreateProductsReply       | CreateProducts           |
| UpdateProductsReply       | UpdateProducts           |
| CreateCustomersReply      | CreateCustomers          |
| UpdateCustomersReply      | UpdateCustomers          |
| CreateRoutesReply         | CreateRoutes             |
| UpdateRoutesReply         | UpdateRoutes             |
| GoodsInReply              | GoodsIn                  |
| InventoryOrderReply       | InventoryOrder           |
| CreateCustomerOrderReply  | CreateCustomerOrder      |
| HOSTPickStatusReply       | HOSTPickStatus           |
| LockUnlockProductReply    | LockUnlockProduct        |
| StorageCountingReply      | StorageCounting          |
| SnapshotReply             | Snapshot                 |
| UserDownloadReply         | UserDownload             |
| ProductsNotDeletedReply   | ProductsNotDeleted       |
| ChannelEmptyReply         | ChannelEmpty (out msg)   |
| ChannelReplenishmentReply | ChannelReplenishment     |
| OrderStatusReply          | OrderStatus              |
| StockCorrectionReply      | StockCorrection          |
| PalletStatusReply         | PalletStatus             |
| InventoryOrderStatusReply | InventoryOrderStatus     |
| SnapshotStatusReply       | SnapshotStatus           |

### 2.3 Outbound Status / Event Messages (One → Host, `SOAD_OUT`)
| RecordType            | Context |
|-----------------------|---------|
| ChannelEmpty          | Channel became empty |
| ChannelReplenishment  | Replenishment performed |
| OrderStatus           | Order life-cycle progression |
| StockCorrection       | Stock adjustment events |
| PalletStatus          | Pallet build / shipping info |
| ProductsNotDeleted    | Product deletions refused |
| InventoryOrderStatus  | Inventory order progress |
| SnapshotStatus        | Snapshot progress events |
| StorageCountingReply* | (Ack path – see table) |

(*Already listed under replies but originates from One side after processing.)

### 2.4 Snapshot File Output (SNAP_OUT)
Snapshot requests (`Snapshot` + later `SnapshotStatus` + final `...SnapshotFinished` variants) produce files written to snapshot output location configured in `hostapp.xml` (transport FILE). Filenames generally incorporate recordType + message ID. Inspect the SNAP_OUT directory or trace after triggering.

---

## 3. XML Envelope Structure

```
<Soad_Envelope>
  <Soad_Header>
    <RequestId>...</RequestId>
    <Ticket>...</Ticket>
  </Soad_Header>
  <Soad_Body>
    <GoodsIn> ... </GoodsIn>
    <!-- or any other single root business element -->
  </Soad_Body>
</Soad_Envelope>
```

Replies mirror the envelope; status/ack roots vary per mapping.

`RequestId` correlation:
- Your sent `RequestId` may be normalized or remapped by HostPretender / host stack (observed `1` in simulated ack). Do not rely on echo of custom RequestId for validation; instead match functional content and presence of corresponding `...Reply`.

`Ticket`:
- Static acceptable for local tests.
- HostPretender may inject `HOST_PRETENDER_SOAD_TICKET` in responses.

---

## 4. Placeholder & Template System

Global placeholder tokens: `{{REQUEST_ID}}`, `{{TICKET}}`, plus message-specific tokens (e.g. `{{ORDER_NR}}`, `{{PRODUCT_CODE_1}}`, etc.)

Unfilled pattern placeholders:
`{{PRODUCT_CODE_N}}`, `{{SLOT_NUMBER_N}}`, etc. are intentionally kept as meta placeholders indicating you can add additional sequenced entities.

Current maintained templates (path: `tools/hcom/templates/`):
| Template File                  | Root          | Purpose |
|--------------------------------|---------------|---------|
| GoodsIn.template.xml           | GoodsIn       | Tote / slot / product inbound |
| CreateProducts.template.xml    | CreateProducts| Channel product master insertion |
| UpdateProducts.template.xml    | UpdateProducts| Modify or delete product-channel |

(Additional templates can be added following same conventions.)

---

## 5. Helper Scripts

### 5.1 Channel Listing
```
tools/hcom/hostpret_list_channels.sh
```
Options:  
- `-c PATH` override hostapp.xml  
- `-r` raw HostPretender output

### 5.2 Request / Ticket Generation (future extensibility)
(If required create a generator script; currently static values embedded in `hostpret_send.sh` or supply via `-r/-k`.)

### 5.3 Send Script
`tools/hcom/hostpret_send.sh`

Features:
- Expands any template file with `{{PLACEHOLDER}}` tokens.
- Substitution ordering ensures `REQUEST_ID` and `TICKET` always set.
- Arbitrary `-D KEY=VALUE` pairs.
- `-x` expansion only (dry-run).
- Verbose mode shows sed script and executed HostPretender command.

Example (GoodsIn):
```
tools/hcom/hostpret_send.sh \
  -t tools/hcom/templates/GoodsIn.template.xml -n SOAD_IN \
  -D ORDER_NR=GI_00010 -D SHEET_NR=001 -D TOTE_NR=OSR1_1-1-1-5 -D CONTAINER_TYPE=11 \
  -D PRODUCT_CODE_1=ProdA -D SLOT_NUMBER_1=1 -D QUANTITY_1=5 -D CAPACITY_1=12 -D TARGET_ZONE_1=O1 \
  -D PRODUCT_CODE_2=ProdB -D SLOT_NUMBER_2=2 -D QUANTITY_2=3 -D CAPACITY_2=15 -v
```

Dry-run:
```
tools/hcom/hostpret_send.sh -t tools/hcom/templates/CreateProducts.template.xml -n SOAD_IN \
  -D STATION_1=70 -D SECTOR_1=1 -D LEVEL_1=1 -D CHANNEL_1=21 -D PRODUCT_CODE_1=Code_21 \
  -D PRODUCT_NAME_1=Name_002 -x
```

Notes:
- Script reports unresolved placeholders so you can fill or ignore them.
- HostPretender may chunk / interleave log lines; rely on trace grep.

---

## 6. Validation Procedure

1. Send message (script).
2. Inspect immediate console output for `ONE-ACK` and absence of errors.
3. Trace inspection (typical paths):
   ```
   grep -i "GoodsIn" wcs/lager/trc/Utilities/HostPretender.*
   grep -i "CreateProductsReply" wcs/lager/trc/Utilities/HostPretender.*
   ```
4. Confirm presence of expected reply root (e.g., `<GoodsInReply ...>`).
5. For master data changes, optionally verify side-effects via subsequent status messages or database (out of scope for host-only workflow).
6. For Snapshot:
   - Send `<Snapshot snapshottype="...">`.
   - Monitor for `SnapshotStatusReply`.
   - Check SNAP_OUT directory (if configured) for generated snapshot files (naming depends on project configuration).
7. For Inventory or Order statuses, poll by capturing `OrderStatus`, `InventoryOrderStatus` outputs after triggering corresponding process flows (manual simulation not covered here).

---

## 7. Ack Derivation Logic (Summary)

Core in C++ (`KiSoftXml.cpp` `prepareConfirmationMessage`): Ack recordType = original message token + `Reply` or `StatusReply` variant (some status sets have distinct types). This mapping aligns with the `EN_*` symbols populating `<Type element="...Reply"...>` entries in the mapping file.

---

## 8. Extending Templates

To add a new template (example: InventoryOrder):
1. Copy envelope skeleton from existing template.
2. Identify required fields from mapping (`InventoryOrder` block).
3. Create placeholders naming pattern: `{{FIELD_NAME}}`.
4. Add file under `tools/hcom/templates/InventoryOrder.template.xml`.
5. Use send script with `-D` assignments.

---

## 9. Placeholder Naming Guidelines

- Use upper snake with numeric suffix for multiple items: `PRODUCT_CODE_1`, `PRODUCT_CODE_2`.
- Collections with variable length: Provide first two as examples; leave pattern placeholder variants (`_N`) commented or left unresolved to signal extensibility.
- Attributes map to placeholders only if sender decides them (e.g. `ordertype`, `fefo`); if static in scenario you may hardcode.

---

## 10. Troubleshooting

| Symptom | Likely Cause | Resolution |
|---------|--------------|-----------|
| Ack shows `RequestId` = 1 | HostPretender normalization | Ignore; rely on functional reply type |
| Missing Reply | Invalid root element or channel mismatch | Revalidate template root, ensure `-n SOAD_IN` |
| Validation failed in send script | hostapp.xml invalid | Run `HostPretender -c wcs/lager/cfg/hostapp.xml -V -n _check` directly |
| Unresolved placeholders warning | Forgot a `-D KEY=VALUE` | Add missing substitutions or ignore if optional |

---

## 11. Snapshot Workflow (Conceptual)

1. Send `<Snapshot snapshottype="STORAGE">` (example type depends on mapping conversion).
2. Wait for `SnapshotReply` (processing accepted).
3. Poll `SnapshotStatus` / `SnapshotStatusReply` for progression.
4. Examine SNAP_OUT directory for `StorageSnapshotFinished` or `InventorySnapshotFinished` outputs (mapping includes finished types).
5. Validate file content semantically if needed (outside scope: parsing logic).

---

## 12. Future Enhancements (Incremental Roadmap)

| Priority | Enhancement | Notes |
|----------|-------------|-------|
| High | Add InventoryOrder.template.xml | Follow GoodsIn pattern |
| High | Add Snapshot.template.xml | Parameterize snapshottype |
| Medium | Batch directory send mode | Loop over folder of expanded XML |
| Medium | Auto-generate numeric sequences (ORDER_NR increment) | Additional `-A` flag |
| Low | Structured log parser script | Summarize recent acks |
| Low | Template linter (detect unmapped placeholders) | Simple grep + mapping cross-check |

---

## 13. Minimal Working Example Recap

Create + send GoodsIn:
```
tools/hcom/hostpret_send.sh -t tools/hcom/templates/GoodsIn.template.xml -n SOAD_IN \
  -D ORDER_NR=GI_DEMO01 -D SHEET_NR=001 -D TOTE_NR=OSR1_DEMO -D CONTAINER_TYPE=11 \
  -D PRODUCT_CODE_1=DemoProdA -D SLOT_NUMBER_1=1 -D QUANTITY_1=4 -D CAPACITY_1=12 -D TARGET_ZONE_1=O1 \
  -D PRODUCT_CODE_2=DemoProdB -D SLOT_NUMBER_2=2 -D QUANTITY_2=2 -D CAPACITY_2=15
```
Check reply:
```
grep -i "GoodsInReply" wcs/lager/trc/Utilities/HostPretender.*
```

---

## 14. Baby Steps Implementation Status

Completed in this iteration:
- Channel listing script
- Request/ticket placeholder strategy (static baseline)
- Core three templates
- Send script + successful GoodsIn send test
- Catalog extraction and documentation (this file)

Pending (future steps):
- Additional templates (InventoryOrder, Snapshot, etc.)
- Snapshot end-to-end validation example
- Automated ack verification helper
- Batch send / mass generation utilities

---

## 15. Reference Files

| Path | Role |
|------|------|
| `wcs/lager/cfg/hostapp.xml` | Channel configuration |
| `wcs/prj/hcom/kisoftxml/wizard/mapping-KiSoftOne22XMLtoEntity.xml` | Canonical mapping & message catalog |
| `wcs/procs/std/HOSTAPP/src/KiSoftXml.cpp` | Ack construction logic |
| `tools/hcom/hostpret_list_channels.sh` | Channel enumeration |
| `tools/hcom/hostpret_send.sh` | Template expansion & send |
| `tools/hcom/templates/*.template.xml` | Message templates |

---

## 16. Validation Commands Quick Reference

```
# List channels
tools/hcom/hostpret_list_channels.sh

# Expand only
tools/hcom/hostpret_send.sh -t tools/hcom/templates/GoodsIn.template.xml -n SOAD_IN -x -D ORDER_NR=GI_X -D SHEET_NR=001 ...

# Send and verbose
tools/hcom/hostpret_send.sh -t tools/hcom/templates/GoodsIn.template.xml -n SOAD_IN -v -D ORDER_NR=GI_X -D SHEET_NR=001 ...

# Find reply
grep -i "GoodsInReply" wcs/lager/trc/Utilities/HostPretender.*

# General ack scan
grep -i "Reply" wcs/lager/trc/Utilities/HostPretender.*

# Snapshot progression (once template added)
grep -i "SnapshotStatus" wcs/lager/trc/Utilities/HostPretender.*
```

---

## 17. Conventions Summary

| Aspect | Convention |
|--------|------------|
| Placeholder style | `{{UPPER_SNAKE_CASE}}` |
| Numeric sequences | Suffix `_1`, `_2` etc. |
| Optional elements | Omit entirely rather than empty tag unless mapping requires presence |
| Multiple barcodes | Increment second index: `BARCODE_1_1`, `BARCODE_1_2` |
| Template comments | Explain each placeholder inline for clarity |
| Baby Steps | Add one new template / script enhancement per commit |

---

End of workflow document.
