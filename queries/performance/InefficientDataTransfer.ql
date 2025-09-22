/**
 * @name Inefficient WASM-JS data transfer
 * @description Large data transfers between WebAssembly and JavaScript without optimization
 * @kind problem
 * @problem.severity warning
 * @precision medium
 * @id js-wasm/inefficient-data-transfer
 * @tags performance
 *       javascript
 *       webassembly
 *       optimization
 */

import javascript

from CallExpr call, ArrayExpr largeArray
where 
  // Large array being passed to WASM
  call.getAnArgument() = largeArray and
  largeArray.getSize() > 1000 and
  call.getCallee().(PropAccess).getPropertyName().matches("%wasm%")
select call, "Large array (" + largeArray.getSize() + " elements) passed to WebAssembly without optimization"