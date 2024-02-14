//
//  File.swift
//  
//
//  Created by Yuki Kuwashima on 2024/02/15.
//

import MetalKit

extension MTLComputePipelineState {
    public func createDispatchSize(
        width: Int,
        height: Int
    ) -> (threadGroupCount: MTLSize, threadsPerThreadGroup: MTLSize) {
        let threadsPerThreadgroup = MTLSize(
            width: self.threadExecutionWidth,
            height: self.maxTotalThreadsPerThreadgroup / self.threadExecutionWidth,
            depth: 1
        )
        let threadGroupCount = MTLSize(
            width: width / threadsPerThreadgroup.width+1,
            height: height / threadsPerThreadgroup.height+1,
            depth: 1
        )
        return (threadGroupCount, threadsPerThreadgroup)
    }
}
